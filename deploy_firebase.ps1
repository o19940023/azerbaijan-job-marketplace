# Firebase Deployment Script for Windows
Write-Host "--- Firebase Projesi Hazirlaniyor ---" -ForegroundColor Cyan

# Check if Firebase CLI is installed
try {
    firebase --version | Out-Null
} catch {
    Write-Host "Firebase CLI yuklu deyil. Yuklenmesi lazim: npm install -g firebase-tools" -ForegroundColor Red
    exit
}

# Login check
Write-Host "Giris yoxlanilir..."
# firebase login

# Deploy everything
Write-Host "Firestore Rules, Storage Rules ve Functions yuklenir..." -ForegroundColor Yellow
firebase deploy --only firestore:rules,storage,functions

Write-Host "--- Emeliyyat Tamamlandi ---" -ForegroundColor Green
