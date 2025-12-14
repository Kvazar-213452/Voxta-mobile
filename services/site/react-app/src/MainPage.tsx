import React, { useEffect, useRef, useState } from "react";
import { Shield, MessageCircle, Smartphone, Lock, Download } from "lucide-react";
import "./mainPage.css";

const VoxtaMessenger: React.FC = () => {
  const particlesRef = useRef<HTMLDivElement | null>(null);
  const trackRef = useRef<HTMLDivElement | null>(null);
  const [currentSlide, setCurrentSlide] = useState<number>(0);

  const totalSlides = 3;

  useEffect(() => {
    const particlesContainer = particlesRef.current;
    if (!particlesContainer) return;

    const particleCount = 50;

    for (let i = 0; i < particleCount; i++) {
      const particle = document.createElement("div");
      particle.className = "particle";

      const size = Math.random() * 4 + 2;
      particle.style.width = `${size}px`;
      particle.style.height = `${size}px`;
      particle.style.left = `${Math.random() * 100}%`;
      particle.style.top = `${Math.random() * 100}%`;
      particle.style.animationDelay = `${Math.random() * 10}s`;
      particle.style.animationDuration = `${Math.random() * 8 + 6}s`;

      particlesContainer.appendChild(particle);
    }

    const handleMouseMove = (e: MouseEvent) => {
      if (Math.random() > 0.95) {
        const particle = document.createElement("div");
        particle.className = "particle";
        particle.style.width = "3px";
        particle.style.height = "3px";
        particle.style.left = `${e.clientX}px`;
        particle.style.top = `${e.clientY}px`;
        particle.style.position = "fixed";
        particle.style.pointerEvents = "none";
        particle.style.zIndex = "1000";
        particle.style.animation = "float 2s ease-out forwards";

        document.body.appendChild(particle);
        setTimeout(() => particle.remove(), 2000);
      }
    };

    document.addEventListener("mousemove", handleMouseMove);

    const handleScroll = () => {
      const particles = document.querySelectorAll<HTMLDivElement>(".particle");
      const scrollPercent =
        window.pageYOffset /
        (document.body.scrollHeight - window.innerHeight);
      particles.forEach((particle, index) => {
        const speed = (index % 3 + 1) * 0.5;
        particle.style.transform = `translateY(${scrollPercent * 100 * speed}px)`;
      });
    };

    window.addEventListener("scroll", handleScroll);

    return () => {
      document.removeEventListener("mousemove", handleMouseMove);
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % totalSlides);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (trackRef.current) {
      trackRef.current.style.transform = `translateX(-${currentSlide * 100}%)`;
    }
  }, [currentSlide]);

  const handleDotClick = (index: number) => setCurrentSlide(index);

  const handleDownload = (e: React.MouseEvent<HTMLButtonElement>) => {
    const btn = e.currentTarget;
    const originalText = btn.textContent || "";

    btn.innerHTML = '<span class="download-loading">⏳ Завантаження...</span>';
    btn.classList.add("downloading");

    setTimeout(() => {
      btn.innerHTML = '<span class="download-success">✅ Завантажено!</span>';
      btn.classList.remove("downloading");
      btn.classList.add("downloaded");
      setTimeout(() => {
        btn.textContent = originalText;
        btn.classList.remove("downloaded");
      }, 2000);
    }, 2000);
  };

  return (
    <div className="voxta-wrapper">
      <div className="particles-container" ref={particlesRef}></div>

      <div className="container">
        <header className="header">
          <div className="avatar">
            <img src="/icon.png" alt="Voxta Logo" className="avatar-image" />
            <div className="avatar-shine"></div>
          </div>
          <div className="header-info">
            <h1 className="header-title">Voxta Messenger</h1>
            <p className="header-description">
              Захищений месенджер з підвищеним рівнем кібербезпеки
            </p>
            <div className="status">
              <span className="status-dot"></span>
              Доступно на Android та Windows
            </div>
          </div>
        </header>

        <div className="carousel-container">
          <div className="carousel">
            <div className="carousel-track" ref={trackRef}>
              <div className="carousel-slide slide1">
                <Shield size={64} />
                <span>Максимальна безпека</span>
              </div>
              <div className="carousel-slide slide2">
                <MessageCircle size={64} />
                <span>Тимчасові чати</span>
              </div>
              <div className="carousel-slide slide3">
                <Smartphone size={64} />
                <span>Багатоплатформеність</span>
              </div>
            </div>
          </div>
          <div className="carousel-nav">
            {[0, 1, 2].map((index) => (
              <div
                key={index}
                className={`nav-dot ${index === currentSlide ? "active" : ""}`}
                onClick={() => handleDotClick(index)}
              ></div>
            ))}
          </div>
        </div>

        <section className="product-description">
          <h2 className="section-title">
            Про месенджер Voxta
            <span className="title-underline"></span>
          </h2>
          <p className="description-text">
            Voxta – це сучасний застосунок для обміну повідомленнями, створений
            на основі технології Flutter. Месенджер забезпечує захищене
            спілкування та дає змогу користувачам повністю контролювати власні
            дані.
          </p>
          <p className="description-text">
            Основна ідея месенджера полягає у поєднанні зручності, швидкодії та
            передових засобів кіберзахисту. Технологічна база включає Node.js,
            Python та Java для серверної частини, MongoDB для зберігання даних, а
            архітектура побудована за мікросервісним принципом.
          </p>

          <div className="features">
            <div className="feature">
              <h3 className="feature-title">
                <Smartphone size={24} />
                Платформеність
              </h3>
              <p className="feature-text">
                Доступна на Android та Windows. Планується розширення на iOS,
                macOS та Linux
              </p>
            </div>

            <div className="feature">
              <h3 className="feature-title">
                <Shield size={24} />
                Підвищена безпека
              </h3>
              <p className="feature-text">
                Всі повідомлення захищені сучасними методами шифрування для
                повної конфіденційності
              </p>
            </div>

            <div className="feature">
              <h3 className="feature-title">
                <MessageCircle size={24} />
                Тимчасові чати
              </h3>
              <p className="feature-text">
                Створення чатів через URL-посилання без реєстрації для анонімних
                розмов
              </p>
            </div>

            <div className="feature">
              <h3 className="feature-title">
                <Lock size={24} />
                Контроль доступу
              </h3>
              <p className="feature-text">
                4-значний код захисту з автоматичним видаленням даних після 3
                невдалих спроб
              </p>
            </div>
          </div>
        </section>

        <div className="download-section">
          <button className="download-btn" onClick={handleDownload}>
            <Download size={24} />
            Завантажити Voxta
          </button>
        </div>
      </div>
    </div>
  );
};

export default VoxtaMessenger;