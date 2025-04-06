// Function to load product data
async function loadProductData() {
    try {
        const response = await fetch('product.json');
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error loading product data:', error);
        return null;
    }
}

// Function to populate shop page
async function populateShopPage() {
    const data = await loadProductData();
    if (!data) return;

    const productContainer = document.querySelector('.row.isotope-grid');
    if (!productContainer) return;

    data.products.forEach(product => {
        const productHTML = `
            <div class="col-sm-6 col-md-4 col-lg-3 p-b-35 isotope-item ${product.category}">
                <div class="block2">
                    <div class="block2-pic hov-img0">
                        <img src="${product.images.find(img => img.isMain).path}" alt="${product.name}">
                        <a href="product-details.html?id=${product.id}" class="block2-btn flex-c-m stext-103 cl2 size-102 bg0 bor2 hov-btn1 p-lr-15 trans-04">
                            Purchase
                        </a>
                    </div>
                    <div class="block2-txt flex-w flex-t p-t-14">
                        <div class="block2-txt-child1 flex-col-l">
                            <a href="product-details.html?id=${product.id}" class="stext-104 cl4 hov-cl1 trans-04 js-name-b2 p-b-6">
                                ${product.name}
                            </a>
                            <span class="stext-105 cl3">
                                ₹${product.price.toLocaleString()}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        `;
        productContainer.insertAdjacentHTML('beforeend', productHTML);
    });
}

// Function to populate featured products on home page
async function populateFeaturedProducts() {
    const data = await loadProductData();
    if (!data) return;

    const featuredContainer = document.querySelector('.row.isotope-grid');
    if (!featuredContainer) return;

    // Filter featured products
    const featuredProducts = data.products.filter(product => product.tags.includes('featured'));
    
    // Clear existing content
    featuredContainer.innerHTML = '';

    // Add featured products
    featuredProducts.forEach(product => {
        const productHTML = `
            <div class="col-sm-6 col-md-4 col-lg-3 p-b-35 isotope-item ${product.category}">
                <div class="block2">
                    <div class="block2-pic hov-img0">
                        <img src="${product.images.find(img => img.isMain).path}" alt="${product.name}">
                        <a href="product-details.html?id=${product.id}" class="block2-btn flex-c-m stext-103 cl2 size-102 bg0 bor2 hov-btn1 p-lr-15 trans-04">
                            Purchase
                        </a>
                    </div>
                    <div class="block2-txt flex-w flex-t p-t-14">
                        <div class="block2-txt-child1 flex-col-l">
                            <a href="product-details.html?id=${product.id}" class="stext-104 cl4 hov-cl1 trans-04 js-name-b2 p-b-6">
                                ${product.name}
                            </a>
                            <span class="stext-105 cl3">
                                ₹${product.price.toLocaleString()}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        `;
        featuredContainer.insertAdjacentHTML('beforeend', productHTML);
    });
}

// Function to populate product details page
async function populateProductDetails() {
    const data = await loadProductData();
    if (!data) return;

    const urlParams = new URLSearchParams(window.location.search);
    const productId = urlParams.get('id');
    const product = data.products.find(p => p.id === productId);
    
    if (!product) return;

    // Add navigation arrows
    const arrowsContainer = document.querySelector('.wrap-slick3-arrows');
    if (arrowsContainer) {
        arrowsContainer.innerHTML = `
            <button class="arrow-slick3 prev-slick3" onclick="navigateImage('prev')" style="left: 0;">
                <i class="fa fa-angle-left" aria-hidden="true"></i>
            </button>
            <button class="arrow-slick3 next-slick3" onclick="navigateImage('next')" style="right: 0;">
                <i class="fa fa-angle-right" aria-hidden="true"></i>
            </button>
        `;
    }

    // Update main image - show only the first image initially
    const mainGallery = document.querySelector('.slick3.gallery-lb');
    if (mainGallery && product.images.length > 0) {
        const mainImage = product.images[0];
        mainGallery.innerHTML = `
            <div class="item-slick3" data-thumb="${mainImage.path}">
                <div class="wrap-pic-w pos-relative">
                    <img src="${mainImage.path}" alt="${mainImage.alt}" id="mainProductImage">
                    <a class="flex-c-m size-108 how-pos1 bor0 fs-16 cl10 bg0 hov-btn3 trans-04" href="${mainImage.path}">
                        <i class="fa fa-expand"></i>
                    </a>
                </div>
            </div>
        `;
    }

    // Add navigation function
    window.navigateImage = function(direction) {
        const totalImages = product.images.length;
        if (typeof window.currentImageIndex === 'undefined') {
            window.currentImageIndex = 0;
        }

        let newIndex;
        if (direction === 'next') {
            newIndex = (window.currentImageIndex + 1) % totalImages;
        } else {
            newIndex = (window.currentImageIndex - 1 + totalImages) % totalImages;
        }

        const selectedImage = product.images[newIndex];
        if (selectedImage) {
            const mainImg = document.getElementById('mainProductImage');
            const mainImgLink = mainImg.nextElementSibling;
            mainImg.src = selectedImage.path;
            mainImg.alt = selectedImage.alt;
            mainImgLink.href = selectedImage.path;

            // Update active thumbnail
            const thumbnails = document.querySelectorAll('.slick3-dots li');
            thumbnails.forEach((thumb, i) => {
                if (i === newIndex) {
                    thumb.classList.add('slick-active');
                } else {
                    thumb.classList.remove('slick-active');
                }
            });

            window.currentImageIndex = newIndex;
        }
    };

    // Initialize current index
    window.currentImageIndex = 0;

    // Update thumbnails
    const thumbnailsContainer = document.querySelector('.wrap-slick3-dots');
    if (thumbnailsContainer) {
        thumbnailsContainer.innerHTML = `
            <ul class="slick3-dots" role="tablist" style="display: block;">
                ${product.images.map((img, index) => `
                    <li class="${index === 0 ? 'slick-active' : ''}" role="presentation">
                        <img src="${img.path}" alt="${img.alt}" onclick="navigateImage('next')">
                        <div class="slick3-dot-overlay"></div>
                    </li>
                `).join('')}
            </ul>
        `;
    }

    // Update product info
    document.querySelector('.js-name-detail').textContent = product.name;
    document.querySelector('.mtext-106.cl2').textContent = `₹${product.price.toLocaleString()}`;
    document.querySelector('.stext-102.cl3.p-t-23').textContent = product.shortDescription;

    // Update included items
    const itemsList = document.querySelector('.included-items');
    if (itemsList) {
        itemsList.innerHTML = product.includedItems.map(item => `
            <li class="stext-102 cl6 p-b-8">
                <i class="fa fa-check m-r-10"></i> ${item}
            </li>
        `).join('');
    }

    // Update product description tab
    const descriptionTab = document.querySelector('#description');
    if (descriptionTab) {
        descriptionTab.innerHTML = `
            <p class="stext-102 cl6">${product.longDescription}</p>
            <h4 class="mtext-105 cl2 p-t-30">Features</h4>
            <ul class="p-l-20 p-t-10">
                ${product.features.map(feature => `
                    <li class="stext-102 cl6 p-b-8">${feature}</li>
                `).join('')}
            </ul>
            <h4 class="mtext-105 cl2 p-t-30">Specifications</h4>
            <ul class="p-l-20 p-t-10">
                <li class="stext-102 cl6 p-b-8">Dimensions: ${product.specifications.dimensions.width}cm × ${product.specifications.dimensions.depth}cm</li>
                <li class="stext-102 cl6 p-b-8">Height Range: ${product.specifications.dimensions.heightRange.min}-${product.specifications.dimensions.heightRange.max}cm</li>
                <li class="stext-102 cl6 p-b-8">Weight: ${product.specifications.weight}</li>
                <li class="stext-102 cl6 p-b-8">Material: ${product.specifications.material}</li>
                <li class="stext-102 cl6 p-b-8">Warranty: ${product.specifications.warranty}</li>
            </ul>
        `;
    }

    // Update reviews tab
    const reviewsTab = document.querySelector('#reviews');
    if (reviewsTab) {
        reviewsTab.innerHTML = `
            ${product.reviews.map(review => `
                <div class="flex-w flex-t p-b-30">
                    <div class="size-207">
                        <div class="flex-w flex-sb-m p-b-2">
                            <span class="mtext-107 cl2 p-r-20">${review.author}</span>
                            <span class="fs-18 cl11">
                                ${'★'.repeat(review.rating)}${'☆'.repeat(5-review.rating)}
                            </span>
                        </div>
                        <p class="stext-102 cl6">${review.comment}</p>
                        <span class="stext-102 cl6 p-t-10">${new Date(review.date).toLocaleDateString()}</span>
                    </div>
                </div>
            `).join('')}
        `;
    }
}

// Initialize based on current page
document.addEventListener('DOMContentLoaded', () => {
    if (window.location.pathname.includes('shop.html')) {
        populateShopPage();
    } else if (window.location.pathname.includes('product-details.html')) {
        populateProductDetails();
    } else if (window.location.pathname === '/' || window.location.pathname.includes('index.html')) {
        populateFeaturedProducts();
    }
}); 