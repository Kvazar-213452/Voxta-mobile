function createParticles() {
    const particlesContainer = document.getElementById('particles');
    const particleCount = 50;

    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        
        const size = Math.random() * 4 + 2;
        particle.style.width = size + 'px';
        particle.style.height = size + 'px';
        
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        
        particle.style.animationDelay = Math.random() * 10 + 's';
        particle.style.animationDuration = (Math.random() * 8 + 6) + 's';
        
        particlesContainer.appendChild(particle);
    }
}

// Carousel functionality
let currentSlide = 0;
const totalSlides = 3;
const track = document.getElementById('carouselTrack');
const dots = document.querySelectorAll('.nav-dot');

function updateCarousel() {
    track.style.transform = `translateX(-${currentSlide * 100}%)`;
    
    dots.forEach((dot, index) => {
        dot.classList.toggle('active', index === currentSlide);
    });
}

function nextSlide() {
    currentSlide = (currentSlide + 1) % totalSlides;
    updateCarousel();
}

// Auto-rotate carousel
setInterval(nextSlide, 5000);

// Dot navigation
dots.forEach((dot, index) => {
    dot.addEventListener('click', () => {
        currentSlide = index;
        updateCarousel();
    });
});

function downloadProduct() {
    const btn = document.querySelector('.download-btn');
    const originalText = btn.innerHTML;
    
    btn.innerHTML = '⏳ Завантаження...';
    btn.style.background = 'linear-gradient(135deg, #666, #888)';
    
    setTimeout(() => {
        btn.innerHTML = '✅ Завантажено!';
        btn.style.background = 'linear-gradient(135deg, #00D084, #4CAF50)';
        
        setTimeout(() => {
            btn.innerHTML = originalText;
        }, 2000);
    }, 2000);
}

// Mouse movement particle effect
document.addEventListener('mousemove', (e) => {
    if (Math.random() > 0.95) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.width = '3px';
        particle.style.height = '3px';
        particle.style.left = e.clientX + 'px';
        particle.style.top = e.clientY + 'px';
        particle.style.position = 'fixed';
        particle.style.pointerEvents = 'none';
        particle.style.zIndex = '1000';
        particle.style.animation = 'float 2s ease-out forwards';
        
        document.body.appendChild(particle);
        
        setTimeout(() => {
            particle.remove();
        }, 2000);
    }
});

// Initialize particles
createParticles();

// Add dynamic particles that respond to scroll
window.addEventListener('scroll', () => {
    const particles = document.querySelectorAll('.particle');
    const scrollPercent = window.pageYOffset / (document.body.scrollHeight - window.innerHeight);
    
    particles.forEach((particle, index) => {
        const speed = (index % 3 + 1) * 0.5;
        particle.style.transform = `translateY(${scrollPercent * 100 * speed}px)`;
    });
});