/**
 * Interactive Animated Furniture Banner
 * Allows users to drag and arrange furniture items on the homepage
 */

class AnimatedBanner {
    constructor(containerId, items, settings) {
        this.container = document.getElementById(containerId);
        this.items = items;
        this.settings = settings;
        this.furnitureElements = [];
        this.draggedElement = null;
        this.offsetX = 0;
        this.offsetY = 0;
        this.originalPositions = new Map();
        this.contextMenu = null;
        this.selectedElement = null;
        this.baseZIndex = 100;
        
        this.init();
    }
    
    init() {
        if (!this.container || !this.settings.is_enabled) return;
        
        // Set container background
        this.container.style.backgroundColor = this.settings.background_color;
        this.container.style.position = 'relative';
        this.container.style.overflow = 'hidden';
        this.container.style.minHeight = '500px';
        
        // Create context menu
        this.createContextMenu();
        
        // Create furniture elements
        this.createFurnitureElements();
        
        // Animate scatter effect on load
        setTimeout(() => this.scatterItems(), 100);
        
        // Add reset button if enabled
        if (this.settings.show_reset_button) {
            this.createResetButton();
        }
        
        // Hide context menu on click outside
        document.addEventListener('click', () => this.hideContextMenu());
    }
    
    createFurnitureElements() {
        this.items.forEach((item, index) => {
            const element = document.createElement('div');
            element.className = 'furniture-item';
            element.dataset.itemId = item.id;
            element.dataset.category = item.category;
            element.style.cssText = `
                position: absolute;
                left: ${item.initial_x}%;
                top: ${item.initial_y}%;
                width: ${item.width}px;
                height: ${item.height}px;
                cursor: ${this.settings.allow_drag ? 'grab' : 'default'};
                transform: translate(-50%, -50%) rotate(${item.rotation_angle}deg);
                transition: all ${this.settings.scatter_duration}ms ${this.settings.scatter_easing};
                z-index: ${100 + index};
                user-select: none;
                -webkit-user-select: none;
            `;
            
            const img = document.createElement('img');
            img.src = item.image_path;
            img.alt = item.name;
            img.draggable = false;
            img.style.cssText = `
                width: 100%;
                height: 100%;
                object-fit: contain;
                pointer-events: none;
            `;
            
            element.appendChild(img);
            this.container.appendChild(element);
            this.furnitureElements.push(element);
            
            // Store original position
            this.originalPositions.set(element, {
                x: item.initial_x,
                y: item.initial_y,
                rotation: item.rotation_angle
            });
            
            // Add drag functionality
            if (this.settings.allow_drag) {
                this.addDragListeners(element);
            }
        });
    }
    
    scatterItems() {
        this.furnitureElements.forEach((element, index) => {
            const item = this.items[index];
            const scatterDistance = item.scatter_distance || this.settings.scatter_distance || 200;
            
            // Calculate random scatter position
            const angle = Math.random() * Math.PI * 2;
            const distance = Math.random() * scatterDistance;
            const scatterX = Math.cos(angle) * distance;
            const scatterY = Math.sin(angle) * distance;
            
            // Calculate random rotation
            const randomRotation = (Math.random() - 0.5) * 60; // -30 to +30 degrees
            
            // Apply scatter transform
            const currentTransform = element.style.transform;
            element.style.transform = `translate(calc(-50% + ${scatterX}px), calc(-50% + ${scatterY}px)) rotate(${item.rotation_angle + randomRotation}deg)`;
            
            // Animate back to original position after scatter
            setTimeout(() => {
                element.style.transform = `translate(-50%, -50%) rotate(${item.rotation_angle}deg)`;
            }, this.settings.scatter_duration);
        });
    }
    
    addDragListeners(element) {
        // Mouse events
        element.addEventListener('mousedown', (e) => this.startDrag(e, element));
        document.addEventListener('mousemove', (e) => this.drag(e));
        document.addEventListener('mouseup', () => this.endDrag());
        
        // Right-click context menu
        element.addEventListener('contextmenu', (e) => this.showContextMenu(e, element));
        
        // Touch events for mobile
        element.addEventListener('touchstart', (e) => this.startDrag(e, element), { passive: false });
        document.addEventListener('touchmove', (e) => this.drag(e), { passive: false });
        document.addEventListener('touchend', () => this.endDrag());
        
        // Long press for mobile context menu
        let longPressTimer;
        element.addEventListener('touchstart', (e) => {
            longPressTimer = setTimeout(() => {
                this.showContextMenu(e, element);
            }, 500);
        });
        element.addEventListener('touchend', () => {
            clearTimeout(longPressTimer);
        });
        element.addEventListener('touchmove', () => {
            clearTimeout(longPressTimer);
        });
    }
    
    startDrag(e, element) {
        e.preventDefault();
        this.draggedElement = element;
        element.style.cursor = 'grabbing';
        element.style.zIndex = 1000;
        element.style.transition = 'none';
        
        const rect = element.getBoundingClientRect();
        const clientX = e.type.includes('touch') ? e.touches[0].clientX : e.clientX;
        const clientY = e.type.includes('touch') ? e.touches[0].clientY : e.clientY;
        
        this.offsetX = clientX - rect.left - rect.width / 2;
        this.offsetY = clientY - rect.top - rect.height / 2;
    }
    
    drag(e) {
        if (!this.draggedElement) return;
        e.preventDefault();
        
        const clientX = e.type.includes('touch') ? e.touches[0].clientX : e.clientX;
        const clientY = e.type.includes('touch') ? e.touches[0].clientY : e.clientY;
        
        const containerRect = this.container.getBoundingClientRect();
        let x = clientX - containerRect.left - this.offsetX;
        let y = clientY - containerRect.top - this.offsetY;
        
        // Snap to grid if enabled
        if (this.settings.snap_to_grid) {
            const gridSize = this.settings.grid_size || 20;
            x = Math.round(x / gridSize) * gridSize;
            y = Math.round(y / gridSize) * gridSize;
        }
        
        // Keep within container bounds
        const elementRect = this.draggedElement.getBoundingClientRect();
        x = Math.max(elementRect.width / 2, Math.min(x, containerRect.width - elementRect.width / 2));
        y = Math.max(elementRect.height / 2, Math.min(y, containerRect.height - elementRect.height / 2));
        
        this.draggedElement.style.left = `${x}px`;
        this.draggedElement.style.top = `${y}px`;
    }
    
    endDrag() {
        if (!this.draggedElement) return;
        
        this.draggedElement.style.cursor = 'grab';
        this.draggedElement.style.transition = `all ${this.settings.scatter_duration}ms ${this.settings.scatter_easing}`;
        this.draggedElement = null;
    }
    
    createResetButton() {
        const resetBtn = document.createElement('button');
        resetBtn.className = 'btn btn-outline-primary reset-furniture-btn';
        resetBtn.innerHTML = '<i class="fas fa-undo"></i> Reset Layout';
        resetBtn.style.cssText = `
            position: absolute;
            bottom: 20px;
            right: 20px;
            z-index: 2000;
            padding: 10px 20px;
            border-radius: 25px;
            font-size: 14px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            transition: all 0.3s ease;
        `;
        
        resetBtn.addEventListener('click', () => this.resetLayout());
        resetBtn.addEventListener('mouseenter', () => {
            resetBtn.style.transform = 'scale(1.05)';
            resetBtn.style.boxShadow = '0 6px 16px rgba(0,0,0,0.2)';
        });
        resetBtn.addEventListener('mouseleave', () => {
            resetBtn.style.transform = 'scale(1)';
            resetBtn.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
        });
        
        this.container.appendChild(resetBtn);
    }
    
    resetLayout() {
        this.furnitureElements.forEach((element) => {
            const original = this.originalPositions.get(element);
            if (original) {
                element.style.left = `${original.x}%`;
                element.style.top = `${original.y}%`;
                element.style.transform = `translate(-50%, -50%) rotate(${original.rotation}deg)`;
            }
        });
        
        // Re-trigger scatter animation
    
    createContextMenu() {
        // Create context menu element
        this.contextMenu = document.createElement('div');
        this.contextMenu.className = 'furniture-context-menu';
        this.contextMenu.style.cssText = `
            position: fixed;
            background: white;
            border: 1px solid #ddd;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            padding: 8px 0;
            z-index: 10000;
            display: none;
            min-width: 180px;
        `;
        
        // Menu items
        const menuItems = [
            { icon: '⬆️', text: 'Bring to Front', action: 'toFront' },
            { icon: '⬇️', text: 'Send to Back', action: 'toBack' },
            { icon: '↗️', text: 'Bring Forward', action: 'forward' },
            { icon: '↘️', text: 'Send Backward', action: 'backward' }
        ];
        
        menuItems.forEach(item => {
            const menuItem = document.createElement('div');
            menuItem.className = 'context-menu-item';
            menuItem.innerHTML = `<span style="margin-right: 8px;">${item.icon}</span>${item.text}`;
            menuItem.style.cssText = `
                padding: 10px 16px;
                cursor: pointer;
                transition: background 0.2s;
                font-size: 14px;
                display: flex;
                align-items: center;
            `;
            
            menuItem.addEventListener('mouseenter', () => {
                menuItem.style.background = '#f0f0f0';
            });
            
            menuItem.addEventListener('mouseleave', () => {
                menuItem.style.background = 'white';
            });
            
            menuItem.addEventListener('click', (e) => {
                e.stopPropagation();
                this.handleZIndexAction(item.action);
                this.hideContextMenu();
            });
            
            this.contextMenu.appendChild(menuItem);
        });
        
        document.body.appendChild(this.contextMenu);
    }
    
    showContextMenu(e, element) {
        e.preventDefault();
        e.stopPropagation();
        
        this.selectedElement = element;
        
        // Position context menu
        const x = e.clientX || (e.touches && e.touches[0].clientX);
        const y = e.clientY || (e.touches && e.touches[0].clientY);
        
        this.contextMenu.style.left = `${x}px`;
        this.contextMenu.style.top = `${y}px`;
        this.contextMenu.style.display = 'block';
        
        // Adjust if menu goes off screen
        setTimeout(() => {
            const rect = this.contextMenu.getBoundingClientRect();
            if (rect.right > window.innerWidth) {
                this.contextMenu.style.left = `${x - rect.width}px`;
            }
            if (rect.bottom > window.innerHeight) {
                this.contextMenu.style.top = `${y - rect.height}px`;
            }
        }, 0);
    }
    
    hideContextMenu() {
        if (this.contextMenu) {
            this.contextMenu.style.display = 'none';
        }
    }
    
    handleZIndexAction(action) {
        if (!this.selectedElement) return;
        
        const currentZ = parseInt(this.selectedElement.style.zIndex) || this.baseZIndex;
        
        switch (action) {
            case 'toFront':
                // Find highest z-index
                const maxZ = Math.max(...this.furnitureElements.map(el => 
                    parseInt(el.style.zIndex) || this.baseZIndex
                ));
                this.selectedElement.style.zIndex = maxZ + 1;
                break;
                
            case 'toBack':
                // Find lowest z-index
                const minZ = Math.min(...this.furnitureElements.map(el => 
                    parseInt(el.style.zIndex) || this.baseZIndex
                ));
                this.selectedElement.style.zIndex = minZ - 1;
                break;
                
            case 'forward':
                // Move one layer up
                this.selectedElement.style.zIndex = currentZ + 1;
                break;
                
            case 'backward':
                // Move one layer down
                this.selectedElement.style.zIndex = currentZ - 1;
                break;
        }
        
        // Add visual feedback
        this.selectedElement.style.transition = 'transform 0.2s ease';
        this.selectedElement.style.transform += ' scale(1.05)';
        setTimeout(() => {
            this.selectedElement.style.transform = this.selectedElement.style.transform.replace(' scale(1.05)', '');
        }, 200);
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    const bannerContainer = document.getElementById('animated-furniture-banner');
    if (bannerContainer && window.furnitureData && window.bannerSettings) {
        new AnimatedBanner('animated-furniture-banner', window.furnitureData, window.bannerSettings);
    }
});

// Made with Bob
