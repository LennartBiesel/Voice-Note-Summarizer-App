from flask import Flask, request, jsonify
import openai
import os
from dotenv import load_dotenv
import whisper

model = whisper.load_model("base", device="cpu")
load_dotenv()

app = Flask(__name__)
openai_api_key = os.getenv('OPENAI_API_KEY')
openai_client = openai.OpenAI(api_key=openai_api_key)

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    # Save the audio file
    audio_path = 'temp_audio.wav'
    file.save(audio_path)
    print("message came in")
    # Use Whisper to transcribe the audio
    transcription = transcribe_video_with_whisper(audio_path)

    print(transcription)  # For debugging
    response = openai_client.chat.completions.create(
        model="gpt-4",
        messages=[
            {
            "role": "system",
            "content": "Summarize this voice message, that is send to me. Make sure to get all the relevant information and names mentioned. And if any questions were asked, I should answer list them below"
            },
            {
            "role": "user",
            "content": transcription
            }
        ],
        temperature=1,
        max_tokens=3000,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0
        )
    gpt_response = response.choices[0].message.content
    return jsonify({"transcript": transcription,"gpt_response":gpt_response}), 200

def transcribe_video_with_whisper(video_path):
    result = model.transcribe(video_path)
    return result['text']

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

