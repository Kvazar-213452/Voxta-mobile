import React, { useEffect, useRef, useState } from "react";
import "./mainPage.css";

const EcoTech: React.FC = () => {
  const particlesRef = useRef<HTMLDivElement | null>(null);
  const trackRef = useRef<HTMLDivElement | null>(null);
  const [currentSlide, setCurrentSlide] = useState<number>(0);

  const totalSlides = 3;

  // === Particles initialization ===
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

    // Mouse movement particles
    const handleMouseMove = (e: MouseEvent | globalThis.MouseEvent) => {
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

    // Scroll effect
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

  // === Carousel auto slide ===
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % totalSlides);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  // === Update carousel transform ===
  useEffect(() => {
    if (trackRef.current) {
      trackRef.current.style.transform = `translateX(-${currentSlide * 100}%)`;
    }
  }, [currentSlide]);

  const handleDotClick = (index: number) => setCurrentSlide(index);

  // === Download Button ===
  const handleDownload = (e: React.MouseEvent<HTMLButtonElement>) => {
    const btn = e.currentTarget;
    const originalText = btn.innerHTML;

    btn.innerHTML = "⏳ Завантаження...";
    btn.style.background = "linear-gradient(135deg, #666, #888)";

    setTimeout(() => {
      btn.innerHTML = "✅ Завантажено!";
      btn.style.background = "linear-gradient(135deg, #00D084, #4CAF50)";
      setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.background = "";
      }, 2000);
    }, 2000);
  };

  return (
    <div>
      <div className="particles-container" ref={particlesRef}></div>

      <div className="container">
        <div className="header">
          <div className="avatar">🌱</div>
          <div className="header-info">
            <h1>EcoTech Solutions</h1>
            <p>Інноваційні екологічні рішення для сталого майбутнього</p>
            <div className="status">Доступно зараз</div>
          </div>
        </div>

        <div className="carousel-container">
          <div className="carousel">
            <div className="carousel-track" ref={trackRef}>
              <div className="carousel-slide slide1">
                🚀 Інноваційні технології
              </div>
              <div className="carousel-slide slide2">🌍 Екологічні рішення</div>
              <div className="carousel-slide slide3">⚡ Енергоефективність</div>
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

        <div className="product-description">
          <h2>Про наш продукт</h2>
          <p>
            EcoTech Solutions представляє революційну платформу для управління
            екологічними процесами. Наше рішення поєднує передові технології
            штучного інтелекту з глибоким розумінням екологічних потреб.
          </p>
          <p>
            Ми створили унікальну систему, яка дозволяє компаніям та
            організаціям ефективно відстежувати, аналізувати та оптимізувати свій
            вплив на навколишнє середовище в режимі реального часу.
          </p>

          <div className="features">
            <div className="feature">
              <h3>🎯 Точний моніторинг</h3>
              <p>Відстеження екологічних показників з точністю до 99.9%</p>
            </div>
            <div className="feature">
              <h3>📊 Аналітика в реальному часі</h3>
              <p>Миттєві звіти та рекомендації для оптимізації процесів</p>
            </div>
            <div className="feature">
              <h3>🔒 Безпека даних</h3>
              <p>Захищена система зберігання з шифруванням банківського рівня</p>
            </div>
            <div className="feature">
              <h3>🌐 Глобальна інтеграція</h3>
              <p>Підтримка міжнародних стандартів та протоколів</p>
            </div>
          </div>
        </div>

        <div className="download-section">
          <button className="download-btn" onClick={handleDownload}>
            📥 Завантажити продукт
          </button>
        </div>
      </div>
    </div>
  );
};

export default EcoTech;
