// Workspace Management JavaScript
// Handles user workspace interactions, uploads, and auto-save

let banner = null;
let autoSaveEnabled = true;
let isDirty = false;

// Initialize workspace when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('Initializing workspace...');
    initializeWorkspace();
    setupUploadHandlers();
    setupAutoSave();
});

// Initialize the animated banner with user's items
function initializeWorkspace() {
    const container = document.getElementById('animated-furniture-banner');
    if (!container) {
        console.error('Banner container not found');
        return;
    }
    
    // Create single banner instance
    if (!banner) {
        banner = new AnimatedBanner(container, window.furnitureData, window.bannerSettings);
        console.log('Workspace initialized with', window.furnitureData.length, 'items');
    }
    
    // Listen for item changes
    container.addEventListener('itemMoved', handleItemChange);
    container.addEventListener('itemRotated', handleItemChange);
}

// Setup file upload handlers
function setupUploadHandlers() {
    const uploadZone = document.getElementById('uploadZone');
    const fileInput = document.getElementById('fileInput');
    
    if (!uploadZone || !fileInput) return;
    
    // Click to upload
    uploadZone.addEventListener('click', function(e) {
        if (e.target.id !== 'fileInput') {
            fileInput.click();
        }
    });
    
    // File selection
    fileInput.addEventListener('change', function(e) {
        handleFiles(e.target.files);
        // Clear the input so the same file can be uploaded again
        e.target.value = '';
    });
    
    // Drag and drop
    uploadZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.add('dragover');
    });
    
    uploadZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.remove('dragover');
    });
    
    uploadZone.addEventListener('drop', function(e) {
        e.preventDefault();
        e.stopPropagation();
        uploadZone.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        handleFiles(files);
    });
}

// Handle uploaded files
async function handleFiles(files) {
    if (!files || files.length === 0) return;
    
    console.log('Processing', files.length, 'files...');
    
    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        // Validate file type
        if (!file.type.startsWith('image/png')) {
            showNotification('Only PNG files are supported', 'error');
            continue;
        }
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            showNotification('File too large. Max size is 5MB', 'error');
            continue;
        }
        
        try {
            await uploadFile(file);
        } catch (error) {
            console.error('Upload error:', error);
            showNotification('Failed to upload ' + file.name, 'error');
        }
    }
}

// Upload single file to server
async function uploadFile(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        
        reader.onload = async function(e) {
            const base64Data = e.target.result;
            
            try {
                const response = await fetch('/api/workspace/upload', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        image_data: base64Data,
                        filename: file.name
                    })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    // Add item to banner
                    addItemToBanner(result.item);
                    
                    // Update stats
                    uploadedToday++;
                    updateStats();
                    
                    showNotification('Item added successfully', 'success');
                    resolve(result);
                } else {
                    showNotification(result.message || 'Upload failed', 'error');
                    reject(new Error(result.message));
                }
            } catch (error) {
                console.error('Upload request failed:', error);
                reject(error);
            }
        };
        
        reader.onerror = function() {
            reject(new Error('Failed to read file'));
        };
        
        reader.readAsDataURL(file);
    });
}

// Add new item to the banner
function addItemToBanner(item) {
    if (!banner) {
        console.error('Banner not initialized');
        return;
    }
    
    // Add to banner's items array
    banner.items.push(item);
    
    // Create and add the element
    const element = banner.createFurnitureElement(item);
    banner.container.appendChild(element);
    
    // Apply scatter animation
    banner.scatterItem(element, item);
    
    console.log('Added item to banner:', item.id);
}

// Handle item position/rotation changes
function handleItemChange(event) {
    isDirty = true;
    
    if (autoSaveEnabled) {
        // Debounce auto-save
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(() => {
            saveWorkspace(true);
        }, 2000); // Save 2 seconds after last change
    }
}

// Setup auto-save functionality
function setupAutoSave() {
    // Save before page unload if there are unsaved changes
    window.addEventListener('beforeunload', function(e) {
        if (isDirty) {
            e.preventDefault();
            e.returnValue = '';
            saveWorkspace(false);
        }
    });
}

// Save workspace state
async function saveWorkspace(isAutoSave = false) {
    if (!banner) return;
    
    const indicator = document.getElementById('saveIndicator');
    const saveText = document.getElementById('saveText');
    
    // Show saving indicator
    if (indicator && saveText) {
        indicator.className = 'save-indicator saving';
        saveText.textContent = 'Saving...';
    }
    
    try {
        // Collect all item states
        const items = [];
        const elements = banner.container.querySelectorAll('.furniture-item');
        
        elements.forEach(element => {
            const itemId = element.dataset.itemId;
            const transform = element.style.transform;
            
            // Parse transform values
            let x = 0, y = 0, rotation = 0, scale = 1;
            
            const translateMatch = transform.match(/translate\(([^,]+),\s*([^)]+)\)/);
            if (translateMatch) {
                x = parseFloat(translateMatch[1]);
                y = parseFloat(translateMatch[2]);
            }
            
            const rotateMatch = transform.match(/rotate\(([^)]+)deg\)/);
            if (rotateMatch) {
                rotation = parseFloat(rotateMatch[1]);
            }
            
            const scaleMatch = transform.match(/scale\(([^)]+)\)/);
            if (scaleMatch) {
                scale = parseFloat(scaleMatch[1]);
            }
            
            items.push({
                id: itemId,
                position_x: x,
                position_y: y,
                rotation_angle: rotation,
                scale_factor: scale,
                z_index: parseInt(element.style.zIndex || 1)
            });
        });
        
        // Send to server
        const response = await fetch('/api/workspace/save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ items })
        });
        
        const result = await response.json();
        
        if (result.success) {
            isDirty = false;
            
            // Show success indicator
            if (indicator && saveText) {
                indicator.className = 'save-indicator saved';
                saveText.textContent = isAutoSave ? 'Auto-saved' : 'Saved';
                
                setTimeout(() => {
                    indicator.style.display = 'none';
                }, 2000);
            }
            
            if (!isAutoSave) {
                showNotification('Workspace saved successfully', 'success');
            }
        } else {
            throw new Error(result.message || 'Save failed');
        }
    } catch (error) {
        console.error('Save error:', error);
        
        if (indicator && saveText) {
            indicator.className = 'save-indicator';
            indicator.style.display = 'none';
        }
        
        if (!isAutoSave) {
            showNotification('Failed to save workspace', 'error');
        }
    }
}

// Clear all items from workspace
async function clearWorkspace() {
    if (!confirm('Are you sure you want to clear all items? This cannot be undone.')) {
        return;
    }
    
    try {
        const response = await fetch('/api/workspace/clear', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Clear banner
            if (banner) {
                banner.container.innerHTML = '';
                banner.items = [];
            }
            
            // Update stats
            updateStats();
            
            showNotification('Workspace cleared', 'success');
        } else {
            throw new Error(result.message || 'Clear failed');
        }
    } catch (error) {
        console.error('Clear error:', error);
        showNotification('Failed to clear workspace', 'error');
    }
}

// Update statistics display
function updateStats() {
    const itemCount = document.getElementById('itemCount');
    const uploadCount = document.getElementById('uploadCount');
    
    if (itemCount && banner) {
        itemCount.textContent = banner.items.length;
    }
    
    if (uploadCount) {
        uploadCount.textContent = uploadedToday;
    }
}

// Show notification to user
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `alert alert-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'info'} alert-dismissible fade show`;
    notification.style.position = 'fixed';
    notification.style.top = '80px';
    notification.style.right = '20px';
    notification.style.zIndex = '9999';
    notification.style.minWidth = '300px';
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

// Export functions for global access
window.saveWorkspace = saveWorkspace;
window.clearWorkspace = clearWorkspace;

// Made with Bob
