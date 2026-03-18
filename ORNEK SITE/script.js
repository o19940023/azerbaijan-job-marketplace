// Custom Cursor (Desktop only)
if (window.innerWidth > 768) {
    const cursorDot = document.createElement('div');
    const cursorRing = document.createElement('div');
    cursorDot.className = 'cursor-dot';
    cursorRing.className = 'cursor-ring';
    document.body.appendChild(cursorDot);
    document.body.appendChild(cursorRing);

    let mouseX = 0, mouseY = 0;
    let ringX = 0, ringY = 0;

    document.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
        
        cursorDot.style.left = mouseX + 'px';
        cursorDot.style.top = mouseY + 'px';
    });

    // Smooth ring follow
    function animateRing() {
        ringX += (mouseX - ringX) * 0.15;
        ringY += (mouseY - ringY) * 0.15;
        
        cursorRing.style.left = ringX - 20 + 'px';
        cursorRing.style.top = ringY - 20 + 'px';
        
        requestAnimationFrame(animateRing);
    }
    animateRing();

    // Cursor interactions
    document.querySelectorAll('a, button, .btn, .app-card, .metric-card').forEach(el => {
        el.addEventListener('mouseenter', () => {
            cursorDot.style.transform = 'scale(2)';
            cursorRing.style.transform = 'scale(1.5)';
            cursorRing.style.borderColor = 'var(--accent)';
        });
        
        el.addEventListener('mouseleave', () => {
            cursorDot.style.transform = 'scale(1)';
            cursorRing.style.transform = 'scale(1)';
            cursorRing.style.borderColor = 'var(--primary)';
        });
    });
}

// Smooth scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Enhanced navbar scroll effect
let lastScroll = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
    
    lastScroll = currentScroll;
});

// Enhanced Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            entry.target.classList.add('animated');
        }
    });
}, observerOptions);

// Observe app cards with stagger effect
document.querySelectorAll('.app-card').forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(50px)';
    card.style.transition = `all 0.8s cubic-bezier(0.4, 0, 0.2, 1) ${index * 0.2}s`;
    observer.observe(card);
});

// Observe metric cards with stagger effect
document.querySelectorAll('.metric-card').forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = `all 0.6s cubic-bezier(0.4, 0, 0.2, 1) ${index * 0.1}s`;
    observer.observe(card);
});

// Enhanced parallax effect for hero orbs (Desktop only)
if (window.innerWidth > 768) {
    window.addEventListener('mousemove', (e) => {
        const orbs = document.querySelectorAll('.gradient-orb');
        const x = e.clientX / window.innerWidth;
        const y = e.clientY / window.innerHeight;
        
        orbs.forEach((orb, index) => {
            const speed = (index + 1) * 30;
            const xMove = (x - 0.5) * speed;
            const yMove = (y - 0.5) * speed;
            orb.style.transform = `translate(${xMove}px, ${yMove}px)`;
        });
    });
}

// Enhanced particle effect with colors (Desktop only)
function createParticle() {
    // Skip particles on mobile
    if (window.innerWidth <= 768) return;
    
    const particle = document.createElement('div');
    const colors = ['var(--primary)', 'var(--purple)', 'var(--accent)', 'var(--pink)'];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    
    particle.className = 'particle';
    particle.style.cssText = `
        position: fixed;
        width: ${2 + Math.random() * 3}px;
        height: ${2 + Math.random() * 3}px;
        background: ${randomColor};
        border-radius: 50%;
        pointer-events: none;
        z-index: 0;
        left: ${Math.random() * 100}vw;
        top: ${Math.random() * 100}vh;
        opacity: 0;
        animation: twinkle ${2 + Math.random() * 3}s infinite, float ${5 + Math.random() * 5}s infinite;
        box-shadow: 0 0 10px ${randomColor};
    `;
    document.body.appendChild(particle);
    
    setTimeout(() => particle.remove(), 8000);
}

// Add enhanced twinkle and float animations
const style = document.createElement('style');
style.textContent = `
    @keyframes twinkle {
        0%, 100% { opacity: 0; transform: scale(0); }
        50% { opacity: 1; transform: scale(1); }
    }
    @keyframes float {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-20px); }
    }
`;
document.head.appendChild(style);

// Reduce particle creation on mobile (or disable completely)
const particleInterval = window.innerWidth > 768 ? 150 : 0;
if (particleInterval > 0) {
    setInterval(createParticle, particleInterval);
}

// Enhanced logo hover effect
const logo = document.querySelector('.logo img');
if (logo) {
    logo.addEventListener('mouseenter', () => {
        logo.style.transform = 'scale(1.1) rotate(-5deg)';
    });
    
    logo.addEventListener('mouseleave', () => {
        logo.style.transform = 'scale(1) rotate(0deg)';
    });
}

// Animated counter for stats
const animateCounter = (element, target, duration = 2000) => {
    const start = 0;
    const increment = target / (duration / 16);
    let current = start;
    
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 16);
};

// Animate stats on scroll
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting && !entry.target.classList.contains('counted')) {
            entry.target.classList.add('counted');
            const statNumbers = entry.target.querySelectorAll('.stat-number');
            statNumbers.forEach(stat => {
                const text = stat.textContent;
                if (!isNaN(text)) {
                    animateCounter(stat, parseInt(text));
                }
            });
            
            // Animate metric values
            const metricValues = entry.target.querySelectorAll('.metric-value');
            metricValues.forEach(metric => {
                const text = metric.textContent.replace(/[^0-9.]/g, '');
                if (!isNaN(text)) {
                    const value = parseFloat(text);
                    const suffix = metric.textContent.replace(text, '');
                    let current = 0;
                    const increment = value / 100;
                    const timer = setInterval(() => {
                        current += increment;
                        if (current >= value) {
                            metric.textContent = value + suffix;
                            clearInterval(timer);
                        } else {
                            metric.textContent = current.toFixed(1) + suffix;
                        }
                    }, 20);
                }
            });
        }
    });
}, { threshold: 0.3 });

const aboutSection = document.querySelector('.about-section');
if (aboutSection) {
    statsObserver.observe(aboutSection);
}

// Add loading animation
window.addEventListener('load', () => {
    document.body.style.opacity = '0';
    setTimeout(() => {
        document.body.style.transition = 'opacity 0.8s ease';
        document.body.style.opacity = '1';
    }, 100);
});

// Add 3D tilt effect to cards (Desktop only)
if (window.innerWidth > 768) {
    document.querySelectorAll('.app-card, .metric-card').forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            
            const rotateX = (y - centerY) / 15;
            const rotateY = (centerX - x) / 15;
            
            card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-10px) scale(1.02)`;
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = '';
        });
    });
}

// Magnetic button effect (Desktop only)
if (window.innerWidth > 768) {
    document.querySelectorAll('.btn').forEach(btn => {
        btn.addEventListener('mousemove', (e) => {
            const rect = btn.getBoundingClientRect();
            const x = e.clientX - rect.left - rect.width / 2;
            const y = e.clientY - rect.top - rect.height / 2;
            
            btn.style.transform = `translate(${x * 0.3}px, ${y * 0.3}px) scale(1.05)`;
        });
        
        btn.addEventListener('mouseleave', () => {
            btn.style.transform = '';
        });
    });
}

// Touch-friendly interactions for mobile
if ('ontouchstart' in window) {
    document.querySelectorAll('.app-card, .metric-card').forEach(card => {
        card.addEventListener('touchstart', () => {
            card.style.transform = 'scale(0.98)';
        });
        
        card.addEventListener('touchend', () => {
            card.style.transform = '';
        });
    });
}

// Scroll reveal animations with intersection observer
const revealElements = document.querySelectorAll('.app-card, .metric-card, .section-title, .about-content');
const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry, index) => {
        if (entry.isIntersecting) {
            // Faster reveal on mobile
            const delay = window.innerWidth > 768 ? index * 100 : 0;
            setTimeout(() => {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }, delay);
        }
    });
}, {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
});

revealElements.forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(50px)';
    // Faster transitions on mobile
    const duration = window.innerWidth > 768 ? '0.8s' : '0.4s';
    el.style.transition = `all ${duration} cubic-bezier(0.4, 0, 0.2, 1)`;
    revealObserver.observe(el);
});

// Detect reduced motion preference
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    // Disable all animations
    document.querySelectorAll('*').forEach(el => {
        el.style.animation = 'none';
        el.style.transition = 'none';
    });
}

console.log('🚀 Qaf Studio - Ultra Premium Experience Loaded');

