/**
 * İş Tap AI — Map Module
 * Interactive OpenStreetMap (Leaflet) view for jobs
 */

export const MapModule = {
    map: null,
    markers: [],

    init(containerId, initialLat = 40.4093, initialLng = 49.8671, zoom = 12) {
        const container = document.getElementById(containerId);
        if (!container) return;

        if (this.map) {
            this.map.remove();
            this.markers = [];
        }

        // Initialize Leaflet map
        this.map = L.map(containerId).setView([initialLat, initialLng], zoom);

        // Dark theme map tiles (CartoDB Dark Matter)
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
            subdomains: 'abcd',
            maxZoom: 19
        }).addTo(this.map);
    },

    renderJobs(jobs, onJobSelect) {
        if (!this.map) return;

        // Clear existing markers
        this.markers.forEach(m => this.map.removeLayer(m));
        this.markers = [];

        // Custom orange pin icon
        const customIcon = L.divIcon({
            className: 'custom-map-pin',
            html: `<div style="
                width: 32px; height: 32px;
                background: linear-gradient(135deg, #FF8C00, #FFA500);
                border: 2px solid #fff;
                border-radius: 50% 50% 50% 0;
                transform: rotate(-45deg);
                box-shadow: 0 4px 14px rgba(255, 140, 0, 0.5);
                display: flex; align-items: center; justify-content: center;
            ">
                <span style="transform: rotate(45deg); font-size: 14px;">💼</span>
            </div>`,
            iconSize: [32, 32],
            iconAnchor: [16, 32],
            popupAnchor: [0, -32]
        });

        jobs.forEach(job => {
            const lat = Number(job.latitude) || 40.4093;
            const lng = Number(job.longitude) || 49.8671;

            const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.map);

            const popupContent = `
                <div style="font-family: 'DM Sans', sans-serif; color: #fff; padding: 4px;">
                    <div style="font-weight: 700; font-size: 15px; margin-bottom: 4px; color: #FF8C00;">${job.title || 'İş elanı'}</div>
                    <div style="font-size: 13px; color: #aaa; margin-bottom: 8px;">${job.companyName || ''} · ${job.district || job.city || ''}</div>
                    <div style="font-weight: 700; font-size: 14px; margin-bottom: 10px;">${job.salaryMin || 0} ₼ / ${job.salaryPeriod || 'aylıq'}</div>
                    <button id="map-job-btn-${job.id}" style="
                        width: 100%; padding: 6px 12px; background: #FF8C00; color: #000;
                        border: none; border-radius: 8px; font-weight: 600; font-size: 12px; cursor: pointer;
                    ">Ətraflı Bax</button>
                </div>
            `;

            marker.bindPopup(popupContent);

            marker.on('popupopen', () => {
                const btn = document.getElementById(`map-job-btn-${job.id}`);
                if (btn) {
                    btn.addEventListener('click', () => {
                        if (onJobSelect) onJobSelect(job);
                    });
                }
            });

            this.markers.push(marker);
        });

        if (this.markers.length > 0) {
            const group = new L.featureGroup(this.markers);
            this.map.fitBounds(group.getBounds().pad(0.1));
        }
    }
};
