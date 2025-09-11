const burger = document.getElementById('burger');
const nav = document.getElementById('navLinks');

burger.addEventListener('click', () => {
    nav.classList.toggle('active');
    burger.classList.toggle('toggle');
});

