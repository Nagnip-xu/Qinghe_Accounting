// 等待DOM内容加载完成
document.addEventListener('DOMContentLoaded', function() {
    // 导航菜单交互
    const menuToggle = document.querySelector('.menu-toggle');
    const navLinks = document.querySelector('.nav-links');
    const navbar = document.querySelector('.navbar');
    
    // 性能优化：使用Intersection Observer实现懒加载
    if ('IntersectionObserver' in window) {
        const lazyImageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const lazyImage = entry.target;
                    if (lazyImage.dataset.src) {
                        lazyImage.src = lazyImage.dataset.src;
                        lazyImage.classList.remove("lazy");
                        lazyImageObserver.unobserve(lazyImage);
                    }
                }
            });
        });

        const lazyImages = document.querySelectorAll("img.lazy");
        lazyImages.forEach(lazyImage => {
            lazyImageObserver.observe(lazyImage);
        });
    } else {
        // 降级处理：不支持IntersectionObserver的浏览器
        let lazyImages = [].slice.call(document.querySelectorAll("img.lazy"));
        let active = false;

        const lazyLoad = function() {
            if (active === false) {
                active = true;

                setTimeout(function() {
                    lazyImages.forEach(function(lazyImage) {
                        if ((lazyImage.getBoundingClientRect().top <= window.innerHeight && lazyImage.getBoundingClientRect().bottom >= 0) && getComputedStyle(lazyImage).display !== "none") {
                            if (lazyImage.dataset.src) {
                                lazyImage.src = lazyImage.dataset.src;
                                lazyImage.classList.remove("lazy");
                            }

                            lazyImages = lazyImages.filter(function(image) {
                                return image !== lazyImage;
                            });

                            if (lazyImages.length === 0) {
                                document.removeEventListener("scroll", lazyLoad);
                                window.removeEventListener("resize", lazyLoad);
                                window.removeEventListener("orientationchange", lazyLoad);
                            }
                        }
                    });

                    active = false;
                }, 200);
            }
        };

        document.addEventListener("scroll", lazyLoad);
        window.addEventListener("resize", lazyLoad);
        window.addEventListener("orientationchange", lazyLoad);
    }
    
    if (menuToggle) {
        menuToggle.addEventListener('click', function() {
            navLinks.classList.toggle('active');
            const isOpen = navLinks.classList.contains('active');
            menuToggle.innerHTML = isOpen ? '<i class="fas fa-times"></i>' : '<i class="fas fa-bars"></i>';
            
            // 添加页面滚动锁定
            if (isOpen) {
                document.body.style.overflow = 'hidden';
            } else {
                document.body.style.overflow = '';
            }
        });
    }
    
    // 滚动时导航栏效果
    let lastScrollY = window.scrollY;
    let isScrollingUp = false;
    let ticking = false;
    
    function updateNavbar() {
        const currentScrollY = window.scrollY;
        isScrollingUp = currentScrollY < lastScrollY;
        
        // 滚动超过一定距离时改变导航栏样式
        if (currentScrollY > 100) {
            navbar.style.padding = '12px 0';
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 4px 6px rgba(15, 23, 42, 0.08)';
        } else {
            navbar.style.padding = '18px 0';
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = 'none';
        }
        
        // 向下滚动且非桌面视图时隐藏移动菜单
        if (!isScrollingUp && navLinks.classList.contains('active') && window.innerWidth < 768) {
            navLinks.classList.remove('active');
            menuToggle.innerHTML = '<i class="fas fa-bars"></i>';
            document.body.style.overflow = '';
        }
        
        lastScrollY = currentScrollY;
        ticking = false;
    }
    
    // 使用requestAnimationFrame优化滚动事件
    window.addEventListener('scroll', function() {
        if (!ticking) {
            window.requestAnimationFrame(function() {
                updateNavbar();
                ticking = false;
            });
            ticking = true;
        }
    });
    
    // 平滑滚动
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            // 关闭移动菜单
            if (navLinks.classList.contains('active')) {
                navLinks.classList.remove('active');
                menuToggle.innerHTML = '<i class="fas fa-bars"></i>';
                document.body.style.overflow = '';
            }
            
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                // 计算导航栏高度
                const navbarHeight = navbar.offsetHeight;
                
                window.scrollTo({
                    top: targetElement.offsetTop - navbarHeight - 20,
                    behavior: 'smooth'
                });
                
                // 更新URL hash，但不触发滚动
                setTimeout(() => {
                    history.pushState(null, null, targetId);
                }, 1000);
            }
        });
    });
    
    // 初始化滚动监听
    setupScrollSpy();
    
    // 初始化截图滑块
    initScreenshotSlider();
    
    // 初始化用户评价轮播
    initTestimonialsSlider();
    
    // 初始化FAQ手风琴效果
    initFaqAccordion();
    
    // 添加视差滚动效果
    initParallaxEffect();
    
    // 添加数字动画效果
    animateStats();
    
    // 添加页面加载动画
    document.body.classList.add('loaded');
});

// 滚动监听，更新导航高亮状态
function setupScrollSpy() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-links a');
    const navbar = document.querySelector('.navbar');
    
    window.addEventListener('scroll', function() {
        const navbarHeight = navbar.offsetHeight;
        let current = '';
        const scrollY = window.scrollY;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop - navbarHeight - 100;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');
            
            if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
                current = sectionId;
            }
        });
        
        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
}

// 截图轮播功能优化
function initScreenshotSlider() {
    const slider = document.querySelector('.screenshot-slider');
    if (!slider) return;
    
    const screenshots = slider.querySelectorAll('.screenshot');
    const prevBtn = document.querySelector('.slider-controls .prev');
    const nextBtn = document.querySelector('.slider-controls .next');
    const dotsContainer = document.querySelector('.slider-controls .dots');
    
    if (screenshots.length === 0) return;
    
    let currentIndex = 0;
    let slideWidth;
    let totalSlides = screenshots.length;
    let autoplayInterval;
    let touchStartX = 0;
    let touchEndX = 0;
    let isDragging = false;
    let startPos = 0;
    let currentTranslate = 0;
    let prevTranslate = 0;
    
    // 创建指示点
    screenshots.forEach((_, index) => {
        const dot = document.createElement('div');
        dot.classList.add('dot');
        if (index === 0) dot.classList.add('active');
        dot.addEventListener('click', () => goToSlide(index));
        dotsContainer.appendChild(dot);
    });
    
    // 更新指示点状态
    function updateDots(index) {
        document.querySelectorAll('.dot').forEach((dot, i) => {
            dot.classList.toggle('active', i === index);
        });
    }
    
    // 滚动到指定幻灯片
    function goToSlide(index) {
        if (index < 0) index = totalSlides - 1;
        if (index >= totalSlides) index = 0;
        
        currentIndex = index;
        
        // 计算滚动位置
        slideWidth = screenshots[0].offsetWidth + 24; // 添加间距
        const scrollPos = index * slideWidth;
        
        // 使用平滑滚动
        slider.scrollTo({
            left: scrollPos,
            behavior: 'smooth'
        });
        
        // 更新指示点
        updateDots(index);
        
        // 重置自动播放
        resetAutoplay();
    }
    
    // 初始化自动播放
    function startAutoplay() {
        autoplayInterval = setInterval(() => {
            goToSlide(currentIndex + 1);
        }, 4000);
    }
    
    // 停止自动播放
    function stopAutoplay() {
        clearInterval(autoplayInterval);
    }
    
    // 重置自动播放
    function resetAutoplay() {
        stopAutoplay();
        startAutoplay();
    }
    
    // 添加按钮事件监听
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            goToSlide(currentIndex - 1);
        });
    }
    
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            goToSlide(currentIndex + 1);
        });
    }
    
    // 添加触摸事件支持
    slider.addEventListener('touchstart', touchStart, { passive: true });
    slider.addEventListener('touchmove', touchMove, { passive: true });
    slider.addEventListener('touchend', touchEnd);
    
    // 触摸开始
    function touchStart(e) {
        touchStartX = getPositionX(e);
        isDragging = true;
        startPos = touchStartX;
    }
    
    // 触摸移动
    function touchMove(e) {
        if (isDragging) {
            const currentPosition = getPositionX(e);
            currentTranslate = prevTranslate + currentPosition - startPos;
        }
    }
    
    // 触摸结束
    function touchEnd(e) {
        isDragging = false;
        touchEndX = getPositionX(e);
        
        const diff = touchStartX - touchEndX;
        const threshold = 50; // 滑动阈值
        
        if (Math.abs(diff) > threshold) {
            if (diff > 0) {
                // 向左滑动，下一张
                goToSlide(currentIndex + 1);
            } else {
                // 向右滑动，上一张
                goToSlide(currentIndex - 1);
            }
        }
    }
    
    // 获取触摸位置
    function getPositionX(e) {
        return e.touches ? e.touches[0].clientX : e.clientX;
    }
    
    // 初始化
    goToSlide(0);
    startAutoplay();
    
    // 鼠标进入停止自动播放
    slider.addEventListener('mouseenter', stopAutoplay);
    // 鼠标离开恢复自动播放
    slider.addEventListener('mouseleave', startAutoplay);
    
    // 为截图添加点击放大功能
    screenshots.forEach(screenshot => {
        const img = screenshot.querySelector('img');
        if (img) {
            img.classList.add('zoomable-img');
        }
    });
    
    // 监听窗口大小变化，重新调整滑块
    window.addEventListener('resize', () => {
        goToSlide(currentIndex);
    });
}

// 添加图片尺寸调整函数
function adjustImageSize(img) {
    // 检查图片是否已加载
    if (img.complete) {
        // 检查图片是否过高
        if (img.naturalHeight > 0) {
            const parentHeight = img.parentElement ? img.parentElement.clientHeight - 60 : 520;
            if (img.naturalHeight > parentHeight) {
                img.style.height = parentHeight + 'px';
                img.style.width = 'auto';
                img.style.objectFit = 'contain';
            }
        }
        
        // 检查图片是否过宽
        if (img.naturalWidth > 0) {
            const parentWidth = img.parentElement ? img.parentElement.clientWidth : 280;
            if (img.naturalWidth > parentWidth * 1.2) {
                img.style.width = '100%';
                img.style.height = 'auto';
                img.style.objectFit = 'contain';
            }
        }
    } else {
        // 如果图片尚未加载完成，添加加载事件
        img.addEventListener('load', function() {
            adjustImageSize(this);
        });
    }
}

// 用户评价轮播功能
function initTestimonialsSlider() {
    const slider = document.querySelector('.testimonials-slider');
    const dotsContainer = document.querySelector('.testimonials-dots');
    
    if (!slider || !dotsContainer) return;
    
    const testimonials = slider.querySelectorAll('.testimonial-card');
    if (testimonials.length === 0) return;
    
    let currentIndex = 0;
    let autoplayInterval;
    
    // 创建指示点
    testimonials.forEach((_, index) => {
        const dot = document.createElement('div');
        dot.classList.add('testimonial-dot');
        if (index === 0) dot.classList.add('active');
        dot.addEventListener('click', () => goToTestimonial(index));
        dotsContainer.appendChild(dot);
    });
    
    // 更新指示点状态
    function updateDots(index) {
        document.querySelectorAll('.testimonial-dot').forEach((dot, i) => {
            dot.classList.toggle('active', i === index);
        });
    }
    
    // 滚动到指定评价
    function goToTestimonial(index) {
        if (index < 0) index = testimonials.length - 1;
        if (index >= testimonials.length) index = 0;
        
        currentIndex = index;
        
        // 计算滚动位置
        const testimonialWidth = testimonials[0].offsetWidth + 30; // 加上gap
        
        // 使用平滑滚动
        slider.scrollTo({
            left: index * testimonialWidth,
            behavior: 'smooth'
        });
        
        updateDots(index);
        resetAutoplay();
    }
    
    // 自动播放功能
    function startAutoplay() {
        stopAutoplay();
        autoplayInterval = setInterval(() => {
            goToTestimonial(currentIndex + 1);
        }, 5000); // 每5秒切换一次
    }
    
    function stopAutoplay() {
        if (autoplayInterval) {
            clearInterval(autoplayInterval);
        }
    }
    
    function resetAutoplay() {
        stopAutoplay();
        startAutoplay();
    }
    
    // 添加触摸滑动支持
    let touchStartX = 0;
    let touchEndX = 0;
    
    slider.addEventListener('touchstart', e => {
        touchStartX = e.changedTouches[0].screenX;
        stopAutoplay();
    }, { passive: true });
    
    slider.addEventListener('touchend', e => {
        touchEndX = e.changedTouches[0].screenX;
        handleSwipe();
        resetAutoplay();
    }, { passive: true });
    
    function handleSwipe() {
        const threshold = 50; // 最小滑动距离
        if (touchStartX - touchEndX > threshold) {
            goToTestimonial(currentIndex + 1); // 向左滑动，下一张
        } else if (touchEndX - touchStartX > threshold) {
            goToTestimonial(currentIndex - 1); // 向右滑动，上一张
        }
    }
    
    // 监听滚动事件，更新当前索引
    slider.addEventListener('scroll', function() {
        const testimonialWidth = testimonials[0].offsetWidth + 30; // 加上gap
        const scrollPosition = slider.scrollLeft;
        const newIndex = Math.round(scrollPosition / testimonialWidth);
        
        if (newIndex !== currentIndex && newIndex >= 0 && newIndex < testimonials.length) {
            currentIndex = newIndex;
            updateDots(currentIndex);
        }
    });
    
    // 鼠标悬停时停止自动播放
    slider.addEventListener('mouseenter', stopAutoplay);
    
    // 鼠标离开时恢复自动播放
    slider.addEventListener('mouseleave', startAutoplay);
    
    // 初始化
    goToTestimonial(0);
    startAutoplay();
    
    // 当用户离开页面时暂停自动播放，返回时恢复
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
            stopAutoplay();
        } else {
            startAutoplay();
        }
    });
}

// FAQ手风琴效果
function initFaqAccordion() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
        const question = item.querySelector('.question');
        
        question.addEventListener('click', () => {
            const isOpen = item.classList.contains('active');
            
            // 关闭所有其他FAQ项
            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                    const otherAnswer = otherItem.querySelector('.answer');
                    otherAnswer.style.maxHeight = '0px';
                }
            });
            
            // 切换当前FAQ项
            item.classList.toggle('active');
            
            // 动画显示/隐藏答案
            const answer = item.querySelector('.answer');
            if (isOpen) {
                answer.style.maxHeight = '0px';
            } else {
                answer.style.maxHeight = answer.scrollHeight + 'px';
            }
        });
    });
    
    // 默认打开第一个FAQ
    if (faqItems.length > 0) {
        faqItems[0].classList.add('active');
        const firstAnswer = faqItems[0].querySelector('.answer');
        if (firstAnswer) {
            firstAnswer.style.maxHeight = firstAnswer.scrollHeight + 'px';
        }
    }
}

// 视差滚动效果
function initParallaxEffect() {
    const parallaxElements = document.querySelectorAll('.parallax');
    let ticking = false;
    
    function updateParallax() {
        const scrollY = window.scrollY;
        
        parallaxElements.forEach(element => {
            const speed = element.dataset.speed || 0.2;
            const offset = scrollY * speed;
            
            element.style.transform = `translateY(${offset}px)`;
        });
        
        ticking = false;
    }
    
    window.addEventListener('scroll', function() {
        if (!ticking) {
            window.requestAnimationFrame(function() {
                updateParallax();
                ticking = false;
            });
            ticking = true;
        }
    });
    
    // 添加视差效果到英雄区域
    const hero = document.querySelector('.hero');
    if (hero) {
        hero.classList.add('parallax');
        hero.dataset.speed = '-0.1';
    }
    
    // 添加视差效果到特性卡片
    const featureCards = document.querySelectorAll('.feature-card');
    featureCards.forEach((card, index) => {
        card.classList.add('parallax');
        card.dataset.speed = `${0.05 + (index % 3) * 0.02}`;
    });
}

// 数字动画效果
function animateStats() {
    const stats = document.querySelectorAll('.stat-item .number');
    
    if (stats.length === 0) return;
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = entry.target;
                const targetValue = parseTargetValue(target.textContent);
                
                // 开始动画
                animateValue(target, 0, targetValue, 2000);
                
                // 只执行一次
                observer.unobserve(target);
            }
        });
    }, { threshold: 0.5 });
    
    stats.forEach(stat => {
        observer.observe(stat);
    });
    
    function parseTargetValue(text) {
        // 处理带+、%等符号的数字
        if (text.includes('+')) {
            return parseInt(text.replace(/\D/g, ''));
        } else if (text.includes('%')) {
            return parseInt(text.replace(/\D/g, ''));
        } else if (text.includes('.')) {
            return parseFloat(text.replace(/[^\d.]/g, ''));
        } else {
            return parseInt(text.replace(/\D/g, ''));
        }
    }
    
    function animateValue(element, start, end, duration) {
        let startTimestamp = null;
        const originalText = element.textContent;
        const hasPlus = originalText.includes('+');
        const hasPercent = originalText.includes('%');
        const isDecimal = originalText.includes('.');
        
        function step(timestamp) {
            if (!startTimestamp) startTimestamp = timestamp;
            const progress = Math.min((timestamp - startTimestamp) / duration, 1);
            let value;
            
            if (isDecimal) {
                value = (progress * (end - start) + start).toFixed(1);
            } else {
                value = Math.floor(progress * (end - start) + start);
            }
            
            let displayText = value;
            if (hasPlus) displayText += '+';
            if (hasPercent) displayText += '%';
            
            element.textContent = displayText;
            
            if (progress < 1) {
                window.requestAnimationFrame(step);
            }
        }
        
        window.requestAnimationFrame(step);
    }
} 