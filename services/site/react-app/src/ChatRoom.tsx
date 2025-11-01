import React, { useState, useEffect, useRef } from 'react';
import { io } from 'socket.io-client';
import { Send, Paperclip, User, Sun, Moon, Info, X, FileText, Image as ImageIcon } from 'lucide-react';
import { useParams } from 'react-router-dom';

import './main.css';

const ChatRoom: React.FC = () => {
  const { id } = useParams();

  const [socket, setSocket] = useState<any>(null);
  const [chatId] = useState<string>(id as string);
  const [chatInfo, setChatInfo] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [newMessage, setNewMessage] = useState<string>('');
  const [userId, setUserId] = useState<string>(''); // Тепер отримуємо від сервера
  const [username] = useState<string>('User');
  const [isConnected, setIsConnected] = useState<boolean>(false);
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [timeRemaining, setTimeRemaining] = useState<number>(60);
  const messagesEndRef = useRef<any>(null);
  const fileInputRef = useRef<any>(null);
  const imageInputRef = useRef<any>(null);
  const chatStartTime = useRef<Date>(new Date());
  const chatDuration: number = 60;

  useEffect(() => {
    const newSocket: any = io('http://localhost:3011', {
      transports: ['websocket', 'polling'],
      reconnection: true,
    });

    newSocket.on('connect', () => {
      console.log('✅ Підключено до сервера');
      setIsConnected(true);
    });

    newSocket.on('disconnect', () => {
      console.log('🔴 Відключено від сервера');
      setIsConnected(false);
    });

    // Отримуємо унікальний userId від сервера
    newSocket.on('user_id_assigned', (data: any) => {
      console.log('Отримано userId:', data.userId);
      setUserId(data.userId);
      // Завантажуємо дані чату після отримання userId
      newSocket.emit('load_chat_info', chatId);
      newSocket.emit('load_chat_content', chatId);
    });

    newSocket.on('load_chat', (config: any) => {
      console.log('Отримано конфіг чату:', config);
      setChatInfo(config);
    });

    newSocket.on('chat_content', (data: any) => {
      console.log('Отримано повідомлення:', data);
      setMessages(data.messages || []);
    });

    newSocket.on('new_message', (message: any) => {
      console.log('Нове повідомлення:', message);
      setMessages((prev: any[]) => [...prev, message]);
    });

    newSocket.on('error', (error: any) => {
      console.error('Помилка:', error);
      alert(error.message);
    });

    setSocket(newSocket);

    return () => {
      newSocket.disconnect();
    };
  }, [chatId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
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

  const toggleTheme = (): void => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  const handleSendMessage = (): void => {
    if (!newMessage.trim() || !socket || !isConnected || !userId) return;

    const message: any = {
      id: Date.now().toString(),
      chatId: chatId,
      type: 'text',
      content: newMessage,
      userId: userId,
      username: username,
      timestamp: new Date().toISOString()
    };

    socket.emit('message', message);
    setNewMessage('');
  };

  const handleKeyPress = (e: any): void => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleImageUpload = (e: any): void => {
    const file: any = e.target.files[0];
    if (!file || !socket || !isConnected || !userId) return;

    const reader: any = new FileReader();
    reader.onload = (event: any): void => {
      const message: any = {
        id: Date.now().toString(),
        chatId: chatId,
        type: 'img',
        content: {
          name: file.name,
          size: file.size,
          data: event.target.result,
          mimeType: file.type
        },
        userId: userId,
        username: username,
        timestamp: new Date().toISOString()
      };

      socket.emit('message', message);
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const handleFileUpload = (e: any): void => {
    const file: any = e.target.files[0];
    if (!file || !socket || !isConnected || !userId) return;

    const reader: any = new FileReader();
    reader.onload = (event: any): void => {
      const message: any = {
        id: Date.now().toString(),
        chatId: chatId,
        type: 'file',
        content: {
          name: file.name,
          size: file.size,
          data: event.target.result,
          mimeType: file.type
        },
        userId: userId,
        username: username,
        timestamp: new Date().toISOString()
      };

      socket.emit('message', message);
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const formatTime = (timestamp: any): string => {
    const date: Date = new Date(timestamp);
    return date.toLocaleTimeString('uk-UA', { hour: '2-digit', minute: '2-digit' });
  };

  const formatFileSize = (bytes: any): string => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
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
        {chatInfo?.avatar && (
          <img src={chatInfo.avatar} alt="Avatar" className="chat-avatar" />
        )}
        <div className="chat-header-info">
          <div className="chat-name">{chatInfo?.name || 'Завантаження...'}</div>
          <div className="chat-status">{isConnected ? 'Активний' : 'Офлайн'}</div>
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
        {messages.length === 0 ? (
          <div className="empty-messages">
            <p>Поки що немає повідомлень. Напишіть перше!</p>
          </div>
        ) : (
          messages.map((msg: any) => (
            <div key={msg.id} className={`message ${msg.userId === userId ? 'sent' : 'received'}`}>
              <div className="message-bubble">                
                {msg.type === 'text' && (
                  <div className="message-text">{msg.content}</div>
                )}

                {msg.type === 'img' && (
                  <>
                    <img src={msg.content.data} alt={msg.content.name} className="message-image" />
                    <div className="message-file-info">
                      <ImageIcon size={14} />
                      <span>{msg.content.name}</span>
                      <span>({formatFileSize(msg.content.size)})</span>
                    </div>
                  </>
                )}

                {msg.type === 'file' && (
                  <div className="message-file">
                    <FileText size={20} />
                    <div className="file-info">
                      <span className="file-name">{msg.content.name}</span>
                      <span className="file-size">{formatFileSize(msg.content.size)}</span>
                    </div>
                    <a
                      href={msg.content.data}
                      download={msg.content.name}
                      className="file-download"
                    >
                      Завантажити
                    </a>
                  </div>
                )}

                <div className="message-time">{formatTime(msg.timestamp)}</div>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="input-area">
        <input
          ref={imageInputRef}
          type="file"
          style={{ display: 'none' }}
          accept="image/*"
          onChange={handleImageUpload}
        />
        <input
          ref={fileInputRef}
          type="file"
          style={{ display: 'none' }}
          onChange={handleFileUpload}
        />
        
        <button
          onClick={() => fileInputRef.current?.click()}
          className="file-btn"
          title="Прикріпити файл"
          disabled={!isConnected || !userId}
        >
          <Paperclip size={18} />
        </button>
        
        <input
          type="text"
          value={newMessage}
          onChange={(e: any) => setNewMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Напишіть повідомлення..."
          className="message-input"
          disabled={!isConnected || !userId}
        />
        
        <button 
          onClick={handleSendMessage} 
          className="send-btn" 
          title="Надіслати"
          disabled={!newMessage.trim() || !isConnected || !userId}
        >
          <Send size={18} />
        </button>
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div className="modal" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={(e: any) => e.stopPropagation()}>
            <div className="modal-header">
              {chatInfo?.avatar && (
                <img src={chatInfo.avatar} alt="Avatar" className="modal-avatar" />
              )}
              <div className="modal-header-info">
                <div className="modal-title">{chatInfo?.name || 'Чат'}</div>
                <div className="chat-status">{isConnected ? 'Активний' : 'Офлайн'}</div>
              </div>
              <button onClick={() => setIsModalOpen(false)} className="close-btn">
                <X size={20} />
              </button>
            </div>
            
            <div className="modal-info">
              <div className="info-item">
                <div className="info-label">Опис</div>
                <div className="info-value">{chatInfo?.desc || 'Немає опису'}</div>
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

              <div className="info-item">
                <div className="info-label">Ваш ID</div>
                <div className="info-value">{userId || 'Завантаження...'}</div>
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
};

export default ChatRoom;