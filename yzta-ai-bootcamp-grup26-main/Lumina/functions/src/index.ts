import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";

// Kütüphaneleri import et
import {TextToSpeechClient} from "@google-cloud/text-to-speech";
import * as pdfParse from "pdf-parse";
import {extractRawText} from "mammoth";

// Firebase Admin SDK'yı başlat
admin.initializeApp();

const firestore = admin.firestore();
const storage = admin.storage();
const ttsClient = new TextToSpeechClient();

export const processDocumentForTTS = functions
  .region("europe-west1")
  .runWith({timeoutSeconds: 300, memory: "1GB"})
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    const bucket = storage.bucket(object.bucket);

    // Sadece 'uploads/' klasöründeki dosyaları işle
    if (!filePath || !filePath.startsWith("uploads/")) {
      console.log("Bu dosya 'uploads/' klasöründe değil, işlem durduruldu.");
      return null;
    }

    // Dosya adından ve yolundan bilgileri çıkar
    const fileName = path.basename(filePath);
    const pathParts = filePath.split("/");
    const userId = pathParts[1]; // uploads/userId/taskId.ext yapısından userId
    const taskIdWithExt = pathParts[2]; // dosya adı uzantısı ile
    const taskId = path.parse(taskIdWithExt).name; // uzantısız task ID
    const taskDocRef = firestore.collection("tasks").doc(taskId);

    try {
      // Görev durumunu 'processing' olarak güncelle
      await taskDocRef.update({
        status: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Dosyayı geçici bir dizine indir
      const tempFilePath = path.join(os.tmpdir(), fileName);
      await bucket.file(filePath).download({destination: tempFilePath});
      console.log(`Dosya ${tempFilePath} konumuna indirildi.`);

      let extractedText = "";

      // Dosya türüne göre metin çıkarma
      if (contentType === "application/pdf") {
        const dataBuffer = fs.readFileSync(tempFilePath);
        const data = await pdfParse(dataBuffer);
        extractedText = data.text;
        console.log("PDF metni başarıyla çıkarıldı.");
      } else if (
        contentType ===
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ) {
        const result = await extractRawText({path: tempFilePath});
        extractedText = result.value;
        console.log("DOCX metni başarıyla çıkarıldı.");
      } else {
        throw new Error(`Desteklenmeyen dosya formatı: ${contentType}`);
      }

      // Metin boş kontrolü
      if (!extractedText.trim()) {
        throw new Error("Dosyadan metin çıkarılamadı veya dosya boş.");
      }

      // Metin çok uzunsa kırp (TTS API limitleri için - 5000 karakter limit)
      const shortText = extractedText.substring(0, 4999);
      console.log(`Çıkarılan metin uzunluğu: ${shortText.length} karakter`);

      // Google Cloud TTS API isteği
      const request = {
        input: {text: shortText},
        voice: {
          languageCode: "tr-TR",
          name: "tr-TR-Wavenet-A", // Türkçe kadın sesi
        },
        audioConfig: {
          audioEncoding: "MP3" as const,
          speakingRate: 1.0, // Normal konuşma hızı
          pitch: 0.0, // Normal ses tonu
        },
      };

      const [response] = await ttsClient.synthesizeSpeech(request);
      console.log("TTS API ile ses dosyası başarıyla oluşturuldu.");

      // Oluşturulan MP3 dosyasını Storage'a yükle
      const audioFileName = `${taskId}.mp3`;
      const audioFilePath = `audio/${userId}/${audioFileName}`;
      const tempAudioPath = path.join(os.tmpdir(), audioFileName);

      if (response.audioContent) {
        fs.writeFileSync(tempAudioPath, response.audioContent, "binary");
        await bucket.upload(tempAudioPath, {
          destination: audioFilePath,
          metadata: {
            contentType: "audio/mpeg",
            customMetadata: {
              originalFileName: fileName,
              taskId: taskId,
              userId: userId,
            },
          },
        });
        console.log(`Ses dosyası ${audioFilePath} konumuna yüklendi.`);
      } else {
        throw new Error("TTS API'den ses içeriği alınamadı.");
      }

      // Ses dosyasının indirilebilir URL'ini al
      const audioFile = bucket.file(audioFilePath);
      const [audioUrl] = await audioFile.getSignedUrl({
        action: "read",
        expires: "03-09-2491", // Uzun süreli bir URL (yaklaşık 500 yıl)
      });

      // Firestore dokümanını güncelle
      await taskDocRef.update({
        status: "completed",
        audioUrl: audioUrl,
        audioPath: audioFilePath,
        processedTextLength: shortText.length,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Görev ${taskId} başarıyla tamamlandı.`);

      // Geçici dosyaları temizle
      fs.unlinkSync(tempFilePath);
      if (fs.existsSync(tempAudioPath)) {
        fs.unlinkSync(tempAudioPath);
      }

      return null;
    } catch (error) {
      console.error(`Hata oluştu - Görev ${taskId}:`, error);

      // Hata durumunda Firestore'u güncelle
      await taskDocRef.update({
        status: "failed",
        errorMessage:
          error instanceof Error ? error.message : "Bilinmeyen bir hata oluştu.",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

// Sağlık kontrolü endpoint'i
export const healthCheck = functions
  .region("europe-west1")
  .https.onRequest((request, response) => {
    response.json({
      status: "ok",
      message: "Lumina TTS Service is running",
      timestamp: new Date().toISOString(),
    });
  });

// Manuel olarak görev durumunu kontrol etme endpoint'i
export const getTaskStatus = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Kullanıcı kimlik doğrulaması kontrolü
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Kullanıcı girişi gerekli."
      );
    }

    const {taskId} = data;
    if (!taskId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Task ID gerekli."
      );
    }

    try {
      const taskDoc = await firestore.collection("tasks").doc(taskId).get();

      if (!taskDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Görev bulunamadı.");
      }

      const taskData = taskDoc.data();

      // Kullanıcının kendi görevini kontrol ettiğinden emin ol
      if (taskData?.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Bu görevi görme yetkiniz yok."
        );
      }

      return {
        taskId: taskDoc.id,
        ...taskData,
      };
    } catch (error) {
      console.error("getTaskStatus hatası:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Görev durumu alınırken hata oluştu."
      );
    }
  }); 