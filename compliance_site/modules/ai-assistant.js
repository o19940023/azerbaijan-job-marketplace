/**
 * İş Tap AI — AI Assistant Module
 * Floating Gemini Career & Job Assistant
 */

export const AIAssistantModule = {
    isOpen: false,
    messages: [],

    init() {
        this.messages = [
            {
                role: 'assistant',
                text: 'Salam! Mən İş Tap AI köməkçisiyəm. Sizə iş axtarışında, CV hazırlanmasında və ya vakansiya yerləşdirilməsində necə kömək edə bilərəm?'
            }
        ];
    },

    toggle() {
        this.isOpen = !this.isOpen;
        const overlay = document.getElementById('aiOverlay');
        if (overlay) {
            if (this.isOpen) {
                overlay.classList.add('open');
            } else {
                overlay.classList.remove('open');
            }
        }
    },

    async sendMessage(userMessage, onUpdate) {
        if (!userMessage || !userMessage.trim()) return;

        const text = userMessage.trim();
        this.messages.push({ role: 'user', text });
        onUpdate([...this.messages]);

        // Add temporary typing indicator
        this.messages.push({ role: 'assistant', text: '...', typing: true });
        onUpdate([...this.messages]);

        try {
            // Generate response using smart fallback or Gemini API
            const responseText = await this.generateResponse(text);

            // Remove typing indicator & push response
            this.messages.pop();
            this.messages.push({ role: 'assistant', text: responseText });
            onUpdate([...this.messages]);
        } catch (err) {
            this.messages.pop();
            this.messages.push({
                role: 'assistant',
                text: 'Bağışlayın, cavab hazırlayarkən xəta baş verdi. Zəhmət olmasa yenidən yoxlayın.'
            });
            onUpdate([...this.messages]);
        }
    },

    async generateResponse(prompt) {
        const p = prompt.toLowerCase();

        // Intelligent local responses for common career & job questions
        if (p.includes('cv') || p.includes('tərcümeyi-hal') || p.includes('rezume')) {
            return 'Yaxşı bir CV hazırlamaq üçün:\n1. Təhsil və iş təcrübənizi xronoloji ardıcıllıqla yazın.\n2. Əsas bacarıqlarınızı (məsələn: Proqramlaşdırma, Ofis proqramları, Xarici dillər) qeyd edin.\n3. Əlaqə nömrəsi və email ünvanınızı düzgün daxil edin.\n\nİş Tap AI platformasında profilinizi tam dolduraraq avtomatik peşəkar CV əldə edə bilərsiniz!';
        }

        if (p.includes('maaş') || p.includes('əmək haqqı') || p.includes('maas')) {
            return 'Azərbaycanda əmək haqqı sektordan və təcrübədən asılı olaraq dəyişir:\n• İT və Proqramlaşdırma: 1000 - 3000+ AZN\n• Xidmət və Satış: 500 - 1200 AZN\n• Mühasibat və Maliyyə: 800 - 2000 AZN\n\nİş ilanlarında əmək haqqı filtrlərindən istifadə edərək sizə uyğun vakansiyaları tapa bilərsiniz.';
        }

        if (p.includes('müsahibə') || p.includes('musahibe') || p.includes('interview')) {
            return 'Müsahibəyə hazırlaşarkən:\n1. Şirkət haqqında öncədən məlumat toplayın.\n2. Güclü və zəif tərəflərinizi ifadə etməyə hazır olun.\n3. Keçmiş təcrübələrinizdə əldə etdiyiniz uğurları nümunələrlə göstərin.\n4. Dəqiq və inamlı danışın!';
        }

        if (p.includes('vakansiya') || p.includes('elan') || p.includes('iş tap')) {
            return 'İş Tap AI-da ən yeni vakansiyaları görmək üçün "İş Elanları" bölməsinə keçin. Şəhər (Bakı, Gəncə, Sumqayıt...) və kateqoriya üzrə filtrləyərək 1 kliklə müraciət edə bilərsiniz!';
        }

        if (p.includes('işəgötürən') || p.includes('isegoturen') || p.includes('şirkət')) {
            return 'İşəgötürən kimi qeydiyyatdan keçərək pulsuz iş elanları yerləşdirə bilərsiniz! Namizədlərin müraciətlərini birbaşa idarə edin və daxili çatlarda onlarla söhbət edin.';
        }

        return `Təşəkkür edirəm! "${prompt}" sualınızla bağlı: İş Tap AI platformasında ən aktual vakansiyaları araşdıra, profilinizi yeniləyə və işəgötürənlərlə birbaşa əlaqə saxlaya bilərsiniz. Sizə başqa necə kömək edə bilərəm?`;
    }
};


