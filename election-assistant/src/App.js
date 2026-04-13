import React, { useState, useRef, useEffect, useCallback } from "react";
import { getResponse } from "./utils/nlp.js";
import "./App.css";
import { TextToSpeech } from "@capacitor-community/text-to-speech";

// ── Category detector (UI only, does NOT affect output content) ────────────
const detectCategory = (text = "", image) => {
  const t = text.toLowerCase();
  if (image && t.includes("flag"))          return { label: "Flag",   emoji: "🏳️" };
  if (image && t.includes("symbol"))        return { label: "Symbol", emoji: "🗳️" };
  if (t.includes("slogan") || t.includes("motto") || t.includes("கடன்"))
                                             return { label: "Slogan", emoji: "📢" };
  if (t.includes("chief minister"))         return { label: "CM",     emoji: "ℹ️" };
  if (t.includes("prime minister"))         return { label: "PM",     emoji: "ℹ️" };
  if (t.includes("leader:"))               return { label: "Party",  emoji: "🗳️" };
  if (t.includes("party:") || t.includes("major parties"))
                                             return { label: "Info",   emoji: "ℹ️" };
  return { label: "Info", emoji: "ℹ️" };
};

// ── Voice params per category (only pitch/rate change, NOT content) ─────────
const voiceParams = {
  Flag:   { rate: 0.95, pitch: 1.0  }, // formal
  Symbol: { rate: 0.95, pitch: 1.0  }, // formal
  Slogan: { rate: 1.05, pitch: 1.15 }, // energetic
  Party:  { rate: 1.0,  pitch: 1.1  }, // confident
  CM:     { rate: 0.9,  pitch: 1.0  }, // calm authoritative
  PM:     { rate: 0.9,  pitch: 1.0  }, // calm authoritative
  Info:   { rate: 1.0,  pitch: 1.0  }, // neutral
};

function App() {
  const [input, setInput]             = useState("");
  const [messages, setMessages]       = useState([]);
  const [isListening, setIsListening] = useState(false);
  const [isLoading, setIsLoading]     = useState(false);
  const chatBoxRef    = useRef(null);
  const handleSendRef = useRef(null);
  const lastQueryRef  = useRef("");

  const isNative =
    typeof window !== "undefined" && window.Capacitor?.isNativePlatform?.();

  // ── Browser Web Speech API (fallback) ───────────────────────────────────
  const recognitionRef = useRef(null);
  useEffect(() => {
    if (!isNative) {
      const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (SR) {
        const r = new SR();
        r.lang = "en-IN"; r.continuous = false; r.interimResults = false;
        r.onstart  = () => setIsListening(true);
        r.onend    = () => setIsListening(false);
        r.onerror  = () => setIsListening(false);
        r.onresult = (e) => handleSendRef.current?.(e.results[0][0].transcript);
        recognitionRef.current = r;
      }
    }
  }, []); // eslint-disable-line

  // ── TTS with dynamic voice style per category ───────────────────────────
  const speakText = useCallback(async (text, category = "Info") => {
    if (!text) return;
    const params = voiceParams[category] || voiceParams.Info;

    const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
    const en = [], ta = [];
    lines.forEach((l) => (/[\u0B80-\u0BFF]/.test(l) ? ta : en).push(l));
    const queue = [];
    if (en.length) queue.push({ lang: "en-IN", text: en.join(". ") });
    if (ta.length) queue.push({ lang: "ta-IN", text: ta.join(" ") });
    if (!queue.length) queue.push({ lang: "en-IN", text });

    if (isNative) {
      try {
        await TextToSpeech.stop();
        for (const { lang, text: t } of queue) {
          await TextToSpeech.speak({
            text: t, lang,
            rate:   params.rate,
            pitch:  params.pitch,
            volume: 1.0,
            category: "ambient",
          });
        }
      } catch (e) { console.warn("TTS:", e); } // eslint-disable-line
    } else {
      const s = window.speechSynthesis; if (!s) return; s.cancel();
      let i = 0;
      const next = () => {
        if (i >= queue.length) return;
        const { lang, text: t } = queue[i++];
        const u = new SpeechSynthesisUtterance(t);
        u.lang = lang; u.rate = params.rate; u.pitch = params.pitch;
        u.onend = () => { if (i < queue.length) setTimeout(next, 400); };
        s.speak(u);
      };
      next();
    }
  }, [isNative]);

  // ── Backend / NLP (UNCHANGED) ────────────────────────────────────────────
  const callBackend = useCallback(async (msg) => {
    try {
      setIsLoading(true);
      const res = await fetch("http://localhost:5000/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: msg }),
      });
      if (!res.ok) throw new Error();
      return await res.json();
    } catch { return getResponse(msg); }
    finally { setIsLoading(false); }
  }, []);

  const appendMessages = useCallback((userText, bot) => {
    const category = detectCategory(bot.text, bot.image);
    setMessages((prev) => [
      ...prev,
      { text: userText, sender: "user" },
      { ...bot, sender: "bot", category, query: userText },
    ]);
    speakText(bot.text, category.label);
  }, [speakText]);

  const handleSend = useCallback(async (msg = null) => {
    const text = (msg || input).trim();
    if (!text) return;
    lastQueryRef.current = text;
    setInput("");
    const bot = await callBackend(text);
    appendMessages(text, bot);
  }, [input, callBackend, appendMessages]);

  useEffect(() => { handleSendRef.current = handleSend; }, [handleSend]);

  // ── Voice Input (UNCHANGED logic) ───────────────────────────────────────
  const startListening = useCallback(async () => {
    if (isNative) {
      const VoiceInput = window.Capacitor?.Plugins?.VoiceInput;
      if (!VoiceInput) return;
      try {
        setIsListening(true);
        const result = await VoiceInput.startListening();
        setIsListening(false);
        const t = result?.transcript?.trim();
        if (t) handleSendRef.current?.(t);
      } catch { setIsListening(false); }
    } else {
      recognitionRef.current?.start();
    }
  }, [isNative]);

  // Auto-scroll
  useEffect(() => {
    chatBoxRef.current?.scrollTo(0, chatBoxRef.current.scrollHeight);
  }, [messages]);

  // ── Slogan renderer: split English / Tamil lines with visual highlight ───
  const renderOutputText = (text, category) => {
    if (!text) return null;
    if (category?.label === "Slogan") {
      return text.split("\n").filter(Boolean).map((line, i) => (
        <span key={i} className="slogan-highlight">{line}</span>
      ));
    }
    return <p>{text}</p>;
  };

  return (
    <div className="app">
      {/* ── Messages ── */}
      <div className="chat-box" ref={chatBoxRef}>
        {messages.map((msg, i) => (
          <div key={i} className={`message ${msg.sender}`}>
            {msg.sender === "user" ? (
              <div className="user-bubble">{msg.text}</div>
            ) : (
              <div className="result-card">
                {/* Card header */}
                <div className="card-header">
                  <span className="card-emoji">{msg.category?.emoji}</span>
                  <span className="card-header-label">🔍 Result — {msg.category?.label}</span>
                </div>

                {/* Meta: category + query */}
                <div className="card-meta">
                  <span className="card-meta-item">
                    <span className="card-meta-label">📂 Category:</span>
                    <span className="card-meta-value">{msg.category?.label}</span>
                  </span>
                  <span className="card-meta-item">
                    <span className="card-meta-label">📌 Query:</span>
                    <span className="card-meta-value">"{msg.query}"</span>
                  </span>
                </div>

                {/* Image (flag/symbol) */}
                {msg.image && (
                  <div className="card-image-wrap">
                    <img src={msg.image} alt={msg.text || "result"} />
                  </div>
                )}

                {/* Output text */}
                {msg.text && (
                  <div className="card-output">
                    <div className="card-meta" style={{marginBottom:6}}>
                      <span className="card-meta-label">📊 Output:</span>
                    </div>
                    {renderOutputText(msg.text, msg.category)}
                  </div>
                )}
              </div>
            )}
          </div>
        ))}

        {isLoading && (
          <div className="message bot">
            <div className="typing-card">
              <span className="dot" /><span className="dot" /><span className="dot" />
            </div>
          </div>
        )}
      </div>

      {/* ── Input ── */}
      <footer className="input-area">
        <div className="input-box">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") handleSend(); }}
            placeholder="Ask about elections…"
          />
          <button type="button" className="primary-button" onClick={() => handleSend()}>
            ➤
          </button>
          <button
            type="button"
            className={`icon-button ${isListening ? "listening" : ""}`}
            onClick={startListening}
          >
            🎤
          </button>
        </div>
        {isListening && <p className="input-hint">🔴 Listening… speak now</p>}
      </footer>
    </div>
  );
}

export default App;