const micBtn = document.getElementById('micBtn');
const status = document.getElementById('status');
const chatHistory = document.getElementById('chat-history');

// 1. Browser-Native STT (Free/Local)
const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
recognition.lang = 'en-US';

micBtn.onmousedown = () => { recognition.start(); status.innerText = "Listening..."; };
micBtn.onmouseup = () => { recognition.stop(); status.innerText = "Processing..."; };

recognition.onresult = async (event) => {
  const transcript = event.results[0][0].transcript;
  appendMessage('You', transcript);
  
  // 2. Call your Gemini-powered backend
  const response = await fetch('/api/chat', {
    method: 'POST',
    body: JSON.stringify({ message: transcript, level: 'Beginner' })
  });
  const data = await response.json();
  
  appendMessage('AI (Spanish)', data.spanish_response);
  playSpanishAudio(data.spanish_response);
};

function appendMessage(sender, text) {
  const div = document.createElement('div');
  div.innerHTML = `<strong>${sender}:</strong> ${text}`;
  chatHistory.appendChild(div);
  chatHistory.scrollTop = chatHistory.scrollHeight;
}

// 3. Browser-Native TTS (Free/Local)
function playSpanishAudio(text) {
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'es-ES';
  window.speechSynthesis.speak(utterance);
}