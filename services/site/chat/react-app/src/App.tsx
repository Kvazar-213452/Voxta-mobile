import React, { useState, useEffect, useRef } from 'react';
import { Sun, Moon, Info, Paperclip, Send, X, FileText } from 'lucide-react';
import './main.css';

interface Message {
  id: number;
  text?: string;
  image?: string;
  file?: string;
  type: 'sent' | 'received';
  time: string;
}

export default function ChatApp() {
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [messages, setMessages] = useState<Message[]>([
    { id: 1, text: 'Привіт! Як справи?', type: 'received', time: '10:30' },
    { id: 2, text: 'Все добре, дякую! А в тебе?', type: 'sent', time: '10:32' }
  ]);
  const [inputValue, setInputValue] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [timeRemaining, setTimeRemaining] = useState<number>(60);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const chatStartTime = useRef<Date>(new Date());
  const chatDuration: number = 60;
  const chatAvatarUrl: string = "https://i.pravatar.cc/150?img=12";
  const chatName: string = "Робочий Чат";

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    const timer = setInterval(() => {
      const now = new Date();
      const elapsed = Math.floor((now.getTime() - chatStartTime.current.getTime()) / 1000 / 60);
      const remaining = chatDuration - elapsed;
      setTimeRemaining(remaining > 0 ? remaining : 0);
    }, 60000);

    return () => clearInterval(timer);
  }, []);

  const scrollToBottom = (): void => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const toggleTheme = (): void => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  const sendMessage = (): void => {
    const text = inputValue.trim();
    if (text) {
      const now = new Date();
      const time = now.getHours().toString().padStart(2, '0') + ':' + 
                   now.getMinutes().toString().padStart(2, '0');
      
      setMessages(prev => [...prev, {
        id: Date.now(),
        text,
        type: 'sent',
        time
      }]);
      setInputValue('');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>): void => {
    if (e.key === 'Enter') {
      sendMessage();
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>): void => {
    const file = e.target.files?.[0];
    if (file) {
      const now = new Date();
      const time = now.getHours().toString().padStart(2, '0') + ':' + 
                   now.getMinutes().toString().padStart(2, '0');
      
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (event) => {
          if (event.target?.result) {
            setMessages(prev => [...prev, {
              id: Date.now(),
              image: event.target!.result as string,
              type: 'sent',
              time
            }]);
          }
        };
        reader.readAsDataURL(file);
      } else {
        setMessages(prev => [...prev, {
          id: Date.now(),
          file: file.name,
          type: 'sent',
          time
        }]);
      }
      e.target.value = '';
    }
  };

  const createdDate = chatStartTime.current.toLocaleDateString('uk-UA', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  return (
    <div className={`chat-container ${theme}`}>
      {/* Header */}
      <div className="chat-header">
        <img src={chatAvatarUrl} alt="Avatar" className="chat-avatar" />
        <div className="chat-header-info">
          <div className="chat-name">{chatName}</div>
          <div className="chat-status">Активний</div>
        </div>
        <div className="header-buttons">
          <button onClick={toggleTheme} className="theme-btn" title="Змінити тему">
            {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
          </button>
          <button onClick={() => setIsModalOpen(true)} className="info-btn" title="Інформація">
            <Info size={20} />
          </button>
        </div>
      </div>

      {/* Messages Area */}
      <div className="messages-area">
        {messages.map((msg) => (
          <div key={msg.id} className={`message ${msg.type}`}>
            <div className="message-bubble">
              {msg.image && (
                <img src={msg.image} alt="Зображення" className="message-image" />
              )}
              {msg.file && (
                <div className="message-file">
                  <FileText size={20} />
                  <span>{msg.file}</span>
                </div>
              )}
              {msg.text && (
                <div className="message-text">{msg.text}</div>
              )}
              <div className="message-time">{msg.time}</div>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="input-area">
        <input
          ref={fileInputRef}
          type="file"
          style={{ display: 'none' }}
          accept="image/*,.pdf,.doc,.docx"
          onChange={handleFileSelect}
        />
        <button
          onClick={() => fileInputRef.current?.click()}
          className="file-btn"
          title="Прикріпити файл"
        >
          <Paperclip size={18} />
        </button>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Напишіть повідомлення..."
          className="message-input"
        />
        <button onClick={sendMessage} className="send-btn" title="Надіслати">
          <Send size={18} />
        </button>
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div className="modal" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <img src={chatAvatarUrl} alt="Avatar" className="modal-avatar" />
              <div className="modal-header-info">
                <div className="modal-title">{chatName}</div>
                <div className="chat-status">Активний</div>
              </div>
              <button onClick={() => setIsModalOpen(false)} className="close-btn">
                <X size={20} />
              </button>
            </div>
            
            <div className="modal-info">
              <div className="info-item">
                <div className="info-label">Опис</div>
                <div className="info-value">Чат для обговорення робочих питань та проектів</div>
              </div>

              <div className="info-item">
                <div className="info-label">Створено</div>
                <div className="info-value">{createdDate}</div>
              </div>

              <div className="info-item">
                <div className="info-label">Час до завершення</div>
                <div className="info-value">
                  {timeRemaining > 0 ? `${timeRemaining} хвилин` : 'Чат завершено'}
                </div>
              </div>

              {timeRemaining <= 10 && (
                <div className="timer-warning">
                  ⚠️ {timeRemaining > 0 ? 'Чат скоро закінчиться!' : 'Час чату закінчився!'}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}