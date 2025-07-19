# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import numpy as np
import cv2
from ultralytics import YOLO
from gtts import gTTS
import io
import time

app = Flask(__name__)
CORS(app) # Tüm kökenlerden gelen isteklere izin ver

# YOLO modelini yükle (model dosyasının yolunu kontrol et)
# Model dosyasının C:\Users\İkbal\trans_bridge\backend\best.pt konumunda olduğundan emin olun
try:
    model = YOLO('best.pt') # Model dosyasının adı
    print("YOLO modeli başarıyla yüklendi.")
except Exception as e:
    print(f"YOLO modeli yüklenirken hata oluştu: {e}")
    model = None # Hata durumunda modeli None olarak ayarla

# Global değişkenler: Algılanan kelimeleri biriktirmek ve zamanlama için
detected_word_history = [] # Algılanan kelimelerin geçmişi
last_word_detection_time = 0.0 # Son kelimenin algılandığı zaman
last_spoken_sentence = "" # En son konuşulan cümle (aynı cümlenin tekrar tekrar konuşulmasını engellemek için)
CONFIDENCE_THRESHOLD = 0.4 # Algılama güven eşiği (bu değerin altındaki algılamalar dikkate alınmaz)
SILENCE_THRESHOLD = 1.5 # Sessizlik eşiği 1.5 saniyeye geri alındı
MIN_WORDS_FOR_SPEECH = 1 # Konuşma için minimum kelime sayısı (tek kelime de konuşulabilir)

# Senin inference.py dosyasından alınan form_sentence mantığı buraya entegre edildi
def form_sentence(words):
    # Kelimeleri küçük harfe çevir ve boşlukları temizle
    words = [w.lower().strip() for w in words] # Her kelimenin başındaki/sonundaki boşlukları temizle

    # Basit kural örnekleri
    if 'dur' in words:
        return "Lütfen dur."

    subjects = {'anne', 'baba', 'kardeş', 'arkadaş'}
    verbs = {'içmek', 'özür-dilemek', 'yemek'} # 'özür-dileme' yerine 'özür-dilemek' olarak düzeltildi

    subject_word = None
    verb_word = None
    other_words = []

    # Kelimeleri özneler ve fiiller olarak ayır
    for w in words:
        if w in subjects and subject_word is None: # Sadece ilk özneyi al
            subject_word = w
        elif w in verbs and verb_word is None: # Sadece ilk fiili al
            verb_word = w
        else:
            other_words.append(w) # Diğer kelimeleri tut

    # Yeni eklenen spesifik kurallar
    if subject_word == 'anne':
        if verb_word == 'yemek':
            return "Anne yiyor."
        elif verb_word == 'özür-dilemek': # Düzeltildi
            return "Anne özür dilerim."
        elif verb_word == 'içmek':
            return "Anne içiyor."
    
    if subject_word == 'kardeş':
        if verb_word == 'yemek':
            return "Kardeş yiyor."
        elif verb_word == 'özür-dilemek': # Düzeltildi
            return "Kardeş özür dilerim."
        elif verb_word == 'içmek':
            return "Kardeş içiyor."

    if subject_word == 'baba':
        if verb_word == 'yemek':
            return "Baba yiyor."
        elif verb_word == 'özür-dilemek': # Düzeltildi
            return "Baba özür dilerim."
        elif verb_word == 'içmek':
            return "Baba içiyor."
            
    if subject_word == 'arkadaş':
        if verb_word == 'yemek':
            return "Arkadaş yemek yiyor."
        elif verb_word == 'özür-dilemek': # Düzeltildi
            return "Arkadaşım özür dilerim."
        elif verb_word == 'içmek': # Arkadaş + içmek için spesifik bir kural verilmemiş, genel kurala düşecek
            pass # Bu durumda aşağıda genel fiil çekimine düşecek


    # Genel özne ve fiil kombinasyonları (eğer yukarıdaki spesifik kurallara uymuyorsa)
    if subject_word and verb_word:
        formatted_verb = verb_word
        if verb_word == 'içmek':
            formatted_verb = 'içiyor'
        elif verb_word == 'özür-dilemek': # Düzeltildi
            formatted_verb = 'özür diliyor'
        elif verb_word == 'yemek':
            formatted_verb = 'yiyor'
        
        # Diğer kelimeleri de cümleye ekle (eğer spesifik kural yoksa)
        if other_words:
            return f"{subject_word.capitalize()} {' '.join(other_words)} {formatted_verb}."
        return f"{subject_word.capitalize()} {formatted_verb}."

    # Soru kalıpları
    if 'nerede' in words:
        for w in words:
            if w in {'tuvalet', 'ev', 'telefon'}:
                return f"{w.capitalize()} nerede?"
        return "Nerede?" # Tek başına "nerede" algılanırsa

    if 'nasıl' in words:
        for w in words:
            if w in {'ev', 'yemek', 'kötü', 'iyi'}:
                return f"{w.capitalize()} nasıl?"
        return "Nasıl?" # Tek başına "nasıl" algılanırsa

    # Kural yoksa kelimeleri birleştir (benzersiz ve sırasını koruyarak)
    seen = set()
    unique_words_ordered = []
    for word in words:
        if word not in seen:
            unique_words_ordered.append(word)
            seen.add(word)
            
    return " ".join(unique_words_ordered).capitalize() + "." # Cümle sonuna nokta ekle

@app.route('/process_frame', methods=['POST'])
def process_frame():
    global detected_word_history, last_word_detection_time, last_spoken_sentence

    if model is None:
        return jsonify({'detected_text': 'YOLO modeli yüklenemedi. Sunucu hatası.', 'audio_base64': None}), 500

    data = request.json
    if 'image' not in data:
        return jsonify({'detected_text': 'Resim verisi bulunamadı.', 'audio_base64': None}), 400

    current_time = time.time()
    current_detected_word = ""
    audio_base64 = None
    display_text = "" # Varsayılan olarak ekranda gösterilecek metin (boş)

    try:
        # Base64 kodlu resmi çöz
        image_data = base64.b64decode(data['image'])
        np_arr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if img is None:
            return jsonify({'detected_text': 'Resim çözümlenemedi.', 'audio_base64': None}), 400

        # YOLO ile tahmin yap
        # Modelin algıladığı tüm nesnelerden en yüksek güvene sahip olanı seçelim
        results = model(img, verbose=False) # verbose=False ile gereksiz konsol çıktılarını azalt

        best_confidence = 0.0
        for r in results:
            boxes = r.boxes
            names = r.names
            for box in boxes:
                cls = int(box.cls[0]) # Sınıf ID'si
                confidence = float(box.conf[0]) # Güven skoru

                if confidence > best_confidence and confidence >= CONFIDENCE_THRESHOLD:
                    best_confidence = confidence
                    current_detected_word = names[cls]

        # Kelime biriktirme mantığı
        # Eğer yeni bir kelime algılandıysa (veya buffer boşsa) ve son kelime aynı değilse
        if current_detected_word and \
           (not detected_word_history or detected_word_history[-1] != current_detected_word):
            detected_word_history.append(current_detected_word)
            last_word_detection_time = current_time
        # Eğer aynı kelime tekrar algılanıyorsa, sadece zamanı güncelle (devam ettiğini belirtmek için)
        elif current_detected_word and detected_word_history and detected_word_history[-1] == current_detected_word:
            last_word_detection_time = current_time
        
        # Ekranda gösterilecek metni güncelle (birikmiş kelimeler)
        if detected_word_history:
            display_text = " ".join(detected_word_history) + "..." # Henüz cümle tamamlanmadıysa "..." ekleyelim


        # Cümle tamamlama ve seslendirme mantığı
        # Eğer bir süredir yeni kelime gelmiyorsa (sessizlik) VEYA yeterli sayıda kelime birikmişse
        if detected_word_history and \
           (current_time - last_word_detection_time > SILENCE_THRESHOLD or len(detected_word_history) >= 5):
            
            sentence_to_speak = form_sentence(detected_word_history) # form_sentence fonksiyonunu kullan
            
            # Sadece yeni bir cümle ise ve minimum kelime sayısını karşılıyorsa konuş
            if sentence_to_speak != last_spoken_sentence and len(detected_word_history) >= MIN_WORDS_FOR_SPEECH:
                print(f"Cümle seslendiriliyor: {sentence_to_speak}")
                try:
                    tts = gTTS(text=sentence_to_speak, lang='tr')
                    audio_byte_stream = io.BytesIO()
                    tts.write_to_fp(audio_byte_stream)
                    audio_byte_stream.seek(0) # Stream'i başa al
                    audio_base64 = base64.b64encode(audio_byte_stream.read()).decode('utf-8')
                    last_spoken_sentence = sentence_to_speak # Son konuşulan cümleyi kaydet
                except Exception as e:
                    print(f"Ses oluşturulurken hata oluştu: {e}")
                finally:
                    # Cümle seslendirildikten sonra veya hata durumunda buffer'ı temizle
                    detected_word_history = []
                    last_word_detection_time = 0.0
            else:
                # Aynı cümle tekrar algılandıysa veya konuşmak için yeterli kelime yoksa, buffer'ı temizle
                detected_word_history = []
                last_word_detection_time = 0.0


        return jsonify({
            'detected_text': display_text, # Ekranda gösterilecek birikmiş metin
            'audio_base64': audio_base64 # Sadece yeni bir cümle oluştuğunda ses
        })

    except Exception as e:
        print(f"İşlem sırasında genel hata: {e}")
        return jsonify({'detected_text': f'Hata: {str(e)}', 'audio_base64': None}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
