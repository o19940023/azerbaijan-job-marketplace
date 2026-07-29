# Requirements Document

## Introduction

This feature adds comprehensive SEO (Search Engine Optimization) and ASO (App Store Optimization) meta tags to the İş Tap AI compliance website to achieve top ranking in Google Azerbaijan for job-related search queries. The optimization targets Azerbaijani job seekers searching for terms like "iş ilan" (job posting), "iş bul" (find job), "vakansiya" (vacancy), and "iş axtarışı" (job search).

## Glossary

- **SEO_System**: The collection of HTML meta tags, structured data, and optimization elements that improve search engine visibility
- **Compliance_Site**: The static HTML website located in the compliance_site folder containing index.html, privacy.html, terms.html, support.html, payment-success.html, and payment-error.html
- **Meta_Tag**: HTML elements in the <head> section that provide metadata about the webpage
- **Structured_Data**: Machine-readable data format (JSON-LD) that helps search engines understand page content
- **Open_Graph**: Protocol that enables web pages to become rich objects in social networks
- **Canonical_URL**: The preferred URL for a page to prevent duplicate content issues
- **Geo_Targeting**: SEO technique to target specific geographic regions (Azerbaijan)
- **Job_Schema**: Schema.org structured data specifically for job postings
- **Organization_Schema**: Schema.org structured data for company/organization information
- **Website_Schema**: Schema.org structured data for website information
- **Breadcrumb_Schema**: Schema.org structured data for navigation hierarchy
- **Local_SEO**: Optimization techniques targeting local search results in Azerbaijan

## Requirements

### Requirement 1: Core SEO Meta Tags

**User Story:** As a job seeker in Azerbaijan, I want the İş Tap AI website to appear at the top of Google search results when I search for job-related terms, so that I can easily discover the platform.

#### Acceptance Criteria

1. THE SEO_System SHALL add a unique, keyword-optimized title tag to each page in Compliance_Site containing primary Azerbaijani job search keywords
2. THE SEO_System SHALL add a meta description tag (150-160 characters) to each page in Compliance_Site that includes target keywords and compelling call-to-action
3. THE SEO_System SHALL add meta keywords tag to each page in Compliance_Site containing relevant Azerbaijani job search terms
4. THE SEO_System SHALL add charset UTF-8 declaration to support Azerbaijani characters (ə, ı, ö, ü, ğ, ş, ç)
5. THE SEO_System SHALL add viewport meta tag for mobile responsiveness on all pages

### Requirement 2: Language and Geographic Targeting

**User Story:** As a search engine crawler, I want to understand that this website targets Azerbaijani-speaking users in Azerbaijan, so that I can show it to the right audience.

#### Acceptance Criteria

1. THE SEO_System SHALL set the html lang attribute to "az" (Azerbaijani) on all pages in Compliance_Site
2. THE SEO_System SHALL add meta content-language tag set to "az-AZ" on all pages
3. THE SEO_System SHALL add geo.region meta tag set to "AZ" (Azerbaijan country code)
4. THE SEO_System SHALL add geo.placename meta tag set to "Azerbaijan" on all pages
5. WHERE the page has location-specific content, THE SEO_System SHALL add geo.position meta tag with Azerbaijan coordinates (40.4093,49.8671)

### Requirement 3: Open Graph Social Media Tags

**User Story:** As a user sharing the İş Tap AI website on social media, I want the link to display with an attractive preview image and description, so that more people click on it.

#### Acceptance Criteria

1. THE SEO_System SHALL add og:title tag to each page in Compliance_Site with page-specific optimized titles
2. THE SEO_System SHALL add og:description tag to each page with compelling Azerbaijani descriptions
3. THE SEO_System SHALL add og:type tag set to "website" for all pages
4. THE SEO_System SHALL add og:url tag with the canonical URL for each page
5. THE SEO_System SHALL add og:image tag pointing to the Logo.png with absolute URL
6. THE SEO_System SHALL add og:image:width and og:image:height tags with actual logo dimensions
7. THE SEO_System SHALL add og:locale tag set to "az_AZ" on all pages
8. THE SEO_System SHALL add og:site_name tag set to "İş Tap AI" on all pages

### Requirement 4: Twitter Card Tags

**User Story:** As a user sharing the website on Twitter/X, I want the link to display with a rich card preview, so that the post is more engaging.

#### Acceptance Criteria

1. THE SEO_System SHALL add twitter:card meta tag set to "summary_large_image" on all pages
2. THE SEO_System SHALL add twitter:title tag with page-specific titles on all pages
3. THE SEO_System SHALL add twitter:description tag with page-specific descriptions on all pages
4. THE SEO_System SHALL add twitter:image tag pointing to Logo.png with absolute URL on all pages

### Requirement 5: Canonical URLs and Indexing Control

**User Story:** As a search engine, I want to know the preferred URL for each page and which pages to index, so that I can avoid duplicate content issues.

#### Acceptance Criteria

1. THE SEO_System SHALL add a canonical link tag to each page in Compliance_Site pointing to its preferred URL
2. THE SEO_System SHALL add meta robots tag set to "index, follow" for index.html, privacy.html, terms.html, and support.html
3. THE SEO_System SHALL add meta robots tag set to "noindex, nofollow" for payment-success.html and payment-error.html
4. THE SEO_System SHALL add meta googlebot tag matching the robots directive on all pages

### Requirement 6: Job Posting Structured Data (Schema.org)

**User Story:** As Google's job search feature, I want to understand the job-related content on this website, so that I can display it in Google for Jobs search results.

#### Acceptance Criteria

1. WHEN index.html is loaded, THE SEO_System SHALL include JSON-LD structured data with @type "JobPosting" for the platform
2. THE Job_Schema SHALL include title property describing the job marketplace platform
3. THE Job_Schema SHALL include description property with detailed Azerbaijani description of the platform
4. THE Job_Schema SHALL include hiringOrganization property with Organization_Schema for "Qaf Studio"
5. THE Job_Schema SHALL include jobLocation property with Azerbaijan geographic data
6. THE Job_Schema SHALL include datePosted property with current date
7. THE Job_Schema SHALL include employmentType property set to "FULL_TIME, PART_TIME, CONTRACTOR"

### Requirement 7: Organization Structured Data

**User Story:** As a search engine, I want to understand the organization behind this website, so that I can display rich snippets with company information.

#### Acceptance Criteria

1. THE SEO_System SHALL include JSON-LD structured data with @type "Organization" on index.html
2. THE Organization_Schema SHALL include name property set to "Qaf Studio"
3. THE Organization_Schema SHALL include url property pointing to the official website
4. THE Organization_Schema SHALL include logo property pointing to Logo.png with absolute URL
5. THE Organization_Schema SHALL include contactPoint property with telephone "+994993269996" and email "qafsuport@gmail.com"
6. THE Organization_Schema SHALL include sameAs property array with social media URLs if available

### Requirement 8: Website and WebPage Structured Data

**User Story:** As a search engine, I want to understand the website structure and individual page purposes, so that I can provide better search results.

#### Acceptance Criteria

1. THE SEO_System SHALL include JSON-LD structured data with @type "WebSite" on index.html
2. THE Website_Schema SHALL include name property set to "İş Tap AI"
3. THE Website_Schema SHALL include url property with the website base URL
4. THE Website_Schema SHALL include potentialAction property with SearchAction for site search functionality
5. THE SEO_System SHALL include JSON-LD structured data with @type "WebPage" on all pages
6. THE WebPage_Schema SHALL include name, description, and url properties specific to each page

### Requirement 9: Breadcrumb Structured Data

**User Story:** As a search engine, I want to understand the navigation hierarchy of the website, so that I can display breadcrumb trails in search results.

#### Acceptance Criteria

1. WHEN a page is not index.html, THE SEO_System SHALL include JSON-LD structured data with @type "BreadcrumbList"
2. THE Breadcrumb_Schema SHALL include itemListElement array with navigation path
3. THE Breadcrumb_Schema SHALL include position property for each breadcrumb item starting from 1
4. THE Breadcrumb_Schema SHALL include item property with @id (URL) and name for each breadcrumb

### Requirement 10: Mobile and Performance Optimization Tags

**User Story:** As a mobile user in Azerbaijan, I want the website to load quickly and display properly on my device, so that I have a good user experience.

#### Acceptance Criteria

1. THE SEO_System SHALL add meta theme-color tag set to the primary brand color on all pages
2. THE SEO_System SHALL add meta apple-mobile-web-app-capable tag set to "yes" on all pages
3. THE SEO_System SHALL add meta apple-mobile-web-app-status-bar-style tag on all pages
4. THE SEO_System SHALL add meta format-detection tag set to "telephone=yes" on all pages
5. THE SEO_System SHALL add link rel="preconnect" for external resources (Google Fonts) on all pages
6. THE SEO_System SHALL add meta http-equiv="X-UA-Compatible" set to "IE=edge" for browser compatibility

### Requirement 11: Favicon and App Icons

**User Story:** As a user bookmarking the website or adding it to my home screen, I want to see the İş Tap AI logo, so that I can easily identify it.

#### Acceptance Criteria

1. THE SEO_System SHALL add link rel="icon" tag pointing to a favicon file on all pages
2. THE SEO_System SHALL add link rel="apple-touch-icon" tag pointing to Logo.png on all pages
3. WHERE multiple icon sizes are available, THE SEO_System SHALL add multiple apple-touch-icon links with sizes attribute

### Requirement 12: Azerbaijani Keyword Optimization

**User Story:** As a job seeker in Azerbaijan, I want to find this website when I search in Azerbaijani language, so that I can access job opportunities in my native language.

#### Acceptance Criteria

1. THE SEO_System SHALL include primary keywords "iş ilan", "iş bul", "vakansiya", "iş axtarışı" in index.html title tag
2. THE SEO_System SHALL include secondary keywords "Azərbaycanda iş", "Bakıda iş", "iş elanları", "CV hazırlama" in meta description
3. THE SEO_System SHALL include tertiary keywords "işəgötürən", "namizəd", "karyera", "maaş" in meta keywords tag
4. THE SEO_System SHALL include location-specific keywords "Bakı", "Gəncə", "Sumqayıt" in relevant meta tags
5. THE SEO_System SHALL ensure keyword density in meta descriptions is between 2-3% for primary keywords

### Requirement 13: Alternative Language Tags

**User Story:** As a search engine, I want to know if this content is available in other languages, so that I can show the appropriate version to users.

#### Acceptance Criteria

1. WHERE content is available only in Azerbaijani, THE SEO_System SHALL add link rel="alternate" hreflang="az" pointing to the current page
2. THE SEO_System SHALL add link rel="alternate" hreflang="x-default" pointing to index.html as the default language version

### Requirement 14: Author and Publisher Information

**User Story:** As a search engine, I want to know who created and published this content, so that I can assess its credibility.

#### Acceptance Criteria

1. THE SEO_System SHALL add meta author tag set to "Qaf Studio" on all pages
2. THE SEO_System SHALL add meta publisher tag set to "Qaf Studio" on all pages
3. THE SEO_System SHALL add meta copyright tag with "© 2026 İş Tap AI. Bütün hüquqlar qorunur." on all pages

### Requirement 15: Page-Specific SEO Content

**User Story:** As a search engine, I want each page to have unique, relevant SEO tags, so that I can rank them appropriately for different search queries.

#### Acceptance Criteria

1. WHEN the page is index.html, THE SEO_System SHALL use title "İş Tap AI - Azərbaycanda İş Elanları, Vakansiya və İş Axtarışı | İş Bul"
2. WHEN the page is privacy.html, THE SEO_System SHALL use title "Məxfilik Siyasəti - İş Tap AI | Şəxsi Məlumatların Qorunması"
3. WHEN the page is terms.html, THE SEO_System SHALL use title "İstifadəçi Şərtləri - İş Tap AI | EULA və Qaydalar"
4. WHEN the page is support.html, THE SEO_System SHALL use title "Dəstək və Kömək - İş Tap AI | Əlaqə və Texniki Dəstək"
5. WHEN the page is payment-success.html, THE SEO_System SHALL use title "Ödəniş Uğurlu - İş Tap AI"
6. WHEN the page is payment-error.html, THE SEO_System SHALL use title "Ödəniş Xətası - İş Tap AI"

### Requirement 16: Sitemap Reference

**User Story:** As a search engine crawler, I want to find a sitemap easily, so that I can discover and index all pages efficiently.

#### Acceptance Criteria

1. THE SEO_System SHALL add link rel="sitemap" tag pointing to sitemap.xml on index.html
2. WHERE sitemap.xml exists, THE SEO_System SHALL ensure it is referenced in the robots.txt file

### Requirement 17: Rich Snippet Optimization

**User Story:** As a search engine, I want detailed structured data, so that I can display rich snippets with ratings, prices, and other enhanced information.

#### Acceptance Criteria

1. WHERE applicable, THE SEO_System SHALL include aggregateRating property in structured data with ratingValue and reviewCount
2. WHERE applicable, THE SEO_System SHALL include offers property in Job_Schema with salary information
3. THE SEO_System SHALL ensure all structured data validates against Schema.org specifications

### Requirement 18: Local Business Schema for Azerbaijan

**User Story:** As a user searching for local job services in Azerbaijan, I want to find İş Tap AI in local search results, so that I can access nearby job opportunities.

#### Acceptance Criteria

1. THE SEO_System SHALL include JSON-LD structured data with @type "LocalBusiness" on index.html
2. THE LocalBusiness_Schema SHALL include address property with Azerbaijan location details
3. THE LocalBusiness_Schema SHALL include geo property with latitude and longitude for Azerbaijan
4. THE LocalBusiness_Schema SHALL include telephone property with "+994993269996"
5. THE LocalBusiness_Schema SHALL include openingHours property with business hours "Mo-Fr 09:00-18:00"

### Requirement 19: Security and Trust Tags

**User Story:** As a user concerned about security, I want to see trust indicators, so that I feel confident using the platform.

#### Acceptance Criteria

1. THE SEO_System SHALL add meta referrer tag set to "no-referrer-when-downgrade" on all pages
2. WHERE HTTPS is enabled, THE SEO_System SHALL ensure all absolute URLs use https:// protocol
3. THE SEO_System SHALL add meta rating tag set to "general" for content rating on all pages

### Requirement 20: Performance Hints and Resource Loading

**User Story:** As a browser, I want hints about which resources to load first, so that I can optimize page load performance.

#### Acceptance Criteria

1. THE SEO_System SHALL add link rel="dns-prefetch" for external domains (fonts.googleapis.com, fonts.gstatic.com) on all pages
2. THE SEO_System SHALL add link rel="preconnect" for critical external resources on all pages
3. WHERE external stylesheets are used, THE SEO_System SHALL add link rel="preload" with as="style" for critical CSS
