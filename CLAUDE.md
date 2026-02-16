# Contexto do Projeto: Localizador de Sites Claro (Maranhão)

Aplicativo Android focado em produtividade para técnicos de campo da Claro no Maranhão. O objetivo é buscar informações técnicas de sites (torres) e facilitar a navegação GPS.

## 🛠 Tecnologias e Arquitetura
- **Framework:** Flutter (Foco exclusivo em Android).
- **Gerenciamento de Estado:** Provider ou Bloc (Manter o mais simples possível).
- **Banco de Dados:** Google Sheets (Consumido via CSV/HTTP) - Custo Zero.
- **Mapas (Visualização):** `Maps_flutter` (Usar apenas para exibir o PIN do site).
- **Rotas (Navegação):** `url_launcher` disparando Intent externo para o App Google Maps (`google.navigation:q=lat,lng`).
- **Design:** Material Design 3 (Identidade Visual Claro: Vermelho #EE1105, Branco, Cinza).

## 📋 Requisitos de Negócio
- **Busca Offline-First:** O app deve ser leve. Ao carregar a lista da planilha uma vez, permitir busca local.
- **Pesquisa Inteligente:** Filtrar por Site ID, Nome do Site ou Município.
- **Informações Obrigatórias:** Nome, Endereço, Coordenadas (Lat/Long), Município, Detentora (Dono da torre) e Tecnologias (2G, 3G, 4G, 5G).
- **Integração de GPS:** Botão direto para abrir a rota no Google Maps nativo do Android.

## 🎨 Especificações de UI/UX (Conforme gerado no Stitch)
- **Tela de Busca:** Barra de pesquisa persistente no topo, lista de cards informativos abaixo.
- **Cores:** Fundo claro, cards brancos com elevação suave, botões de ação em Vermelho Claro.
- **Interação:** Ao clicar no card, transição suave para a tela de detalhes.

## 📂 Estrutura de Dados (Mock/Planilha)
Os dados seguem este padrão de colunas:
`site_id, nome, endereco, municipio, latitude, longitude, detentora,UC,  tecnologias`

## 🚀 Comandos de Desenvolvimento (Referência)
- `flutter run` - Iniciar o app no emulador/dispositivo.
- `flutter build apk --release` - Gerar o instalador para os técnicos.
- `flutter pub get` - Instalar dependências.

---
### CÓDIGO GERADO PELO STITCH (Referência de UI)
Abaixo está a estrutura base gerada para as telas:

```html
<!DOCTYPE html>

<html lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Localizador de Sites - MA</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f01105",
                        "background-light": "#f8f6f5",
                        "background-dark": "#23100f",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
        }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
</head>
<body class="bg-background-light dark:bg-background-dark min-h-screen text-slate-900 dark:text-slate-100">
<div class="relative flex h-full min-h-screen w-full flex-col overflow-x-hidden">
<!-- Header Section -->
<header class="sticky top-0 z-50 bg-white dark:bg-zinc-900 border-b border-primary/10 px-4 py-3 flex items-center justify-between shadow-sm">
<div class="flex items-center gap-3">
<!-- Claro Style Logo Element -->
<div class="bg-primary h-8 w-8 rounded-full flex items-center justify-center shadow-md shadow-primary/20">
<span class="material-symbols-outlined text-white text-xl">cell_tower</span>
</div>
<h1 class="text-lg font-bold tracking-tight text-slate-800 dark:text-white">Localizador de Sites <span class="text-primary">- MA</span></h1>
</div>
<button class="p-2 hover:bg-slate-100 dark:hover:bg-zinc-800 rounded-full transition-colors">
<span class="material-symbols-outlined text-slate-600 dark:text-zinc-400">account_circle</span>
</button>
</header>
<!-- Search Bar Section (Floating Style) -->
<div class="px-4 py-4 sticky top-[60px] z-40 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md">
<div class="relative flex w-full items-center">
<div class="absolute left-3 text-primary">
<span class="material-symbols-outlined">search</span>
</div>
<input class="w-full h-12 pl-10 pr-4 rounded-xl border-none bg-white dark:bg-zinc-800 shadow-md focus:ring-2 focus:ring-primary/50 text-base placeholder:text-slate-400 dark:placeholder:text-zinc-500 transition-all" placeholder="Buscar por nome ou ID..." type="text"/>
<button class="absolute right-3 bg-primary/10 p-1 rounded-lg">
<span class="material-symbols-outlined text-primary text-sm">tune</span>
</button>
</div>
</div>
<!-- Filter Chips -->
<div class="flex gap-2 px-4 pb-4 overflow-x-auto no-scrollbar">
<button class="flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full bg-primary px-4 text-white shadow-sm">
<span class="text-sm font-semibold leading-normal">Todos</span>
</button>
<button class="flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full bg-white dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 px-4 text-slate-600 dark:text-zinc-300">
<span class="text-sm font-medium leading-normal">São Luís</span>
</button>
<button class="flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full bg-white dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 px-4 text-slate-600 dark:text-zinc-300">
<span class="text-sm font-medium leading-normal">Imperatriz</span>
</button>
<button class="flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full bg-white dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 px-4 text-slate-600 dark:text-zinc-300">
<span class="text-sm font-medium leading-normal">Caxias</span>
</button>
</div>
<!-- Main Content Area: ListView -->
<main class="flex-1 px-4 space-y-4 pb-24">
<div class="flex justify-between items-center px-1">
<h3 class="text-sm font-bold uppercase tracking-wider text-slate-500 dark:text-zinc-400">Sites Encontrados (3)</h3>
<span class="material-symbols-outlined text-slate-400 text-lg">sort</span>
</div>
<!-- Card 1 -->
<div class="bg-white dark:bg-zinc-900 rounded-xl p-4 shadow-sm border border-slate-100 dark:border-zinc-800 flex flex-col gap-3 group active:scale-[0.98] transition-all">
<div class="flex justify-between items-start">
<div class="space-y-1">
<div class="flex items-center gap-2">
<span class="text-xs font-bold bg-primary/10 text-primary px-1.5 py-0.5 rounded">SLZ001 | MASLS7</span>
<h2 class="text-base font-bold text-slate-800 dark:text-white">São Luís Centro</h2>
</div>
<p class="text-sm text-slate-500 dark:text-zinc-400 flex items-center gap-1">
<span class="material-symbols-outlined text-sm">location_on</span> São Luís, MA
                        </p><p class="text-[11px] font-medium text-slate-400 dark:text-zinc-500 flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">receipt</span> UC: 12345678</p>
</div>
<button class="p-2 bg-slate-50 dark:bg-zinc-800 rounded-lg text-primary">
<span class="material-symbols-outlined">map</span>
</button>
</div>
<div class="flex gap-2 mt-1">
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary text-white">4G</span>
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary text-white">5G</span>
<span class="ml-auto flex items-center text-xs font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 px-2 py-0.5 rounded">
<span class="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1"></span> Ativo
                    </span>
</div>
</div>
<!-- Card 2 -->
<div class="bg-white dark:bg-zinc-900 rounded-xl p-4 shadow-sm border border-slate-100 dark:border-zinc-800 flex flex-col gap-3 group active:scale-[0.98] transition-all">
<div class="flex justify-between items-start">
<div class="space-y-1">
<div class="flex items-center gap-2">
<span class="text-xs font-bold bg-primary/10 text-primary px-1.5 py-0.5 rounded">ITZ045 | MAITZ2</span>
<h2 class="text-base font-bold text-slate-800 dark:text-white">Imperatriz Matriz</h2>
</div>
<p class="text-sm text-slate-500 dark:text-zinc-400 flex items-center gap-1">
<span class="material-symbols-outlined text-sm">location_on</span> Imperatriz, MA
                        </p><p class="text-[11px] font-medium text-slate-400 dark:text-zinc-500 flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">receipt</span> UC: 87654321</p>
</div>
<button class="p-2 bg-slate-50 dark:bg-zinc-800 rounded-lg text-primary">
<span class="material-symbols-outlined">map</span>
</button>
</div>
<div class="flex gap-2 mt-1">
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary text-white">4G</span>
<span class="ml-auto flex items-center text-xs font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 px-2 py-0.5 rounded">
<span class="w-1.5 h-1.5 rounded-full bg-emerald-500 mr-1"></span> Ativo
                    </span>
</div>
</div>
<!-- Card 3 -->
<div class="bg-white dark:bg-zinc-900 rounded-xl p-4 shadow-sm border border-slate-100 dark:border-zinc-800 flex flex-col gap-3 group active:scale-[0.98] transition-all">
<div class="flex justify-between items-start">
<div class="space-y-1">
<div class="flex items-center gap-2">
<span class="text-xs font-bold bg-primary/10 text-primary px-1.5 py-0.5 rounded">CXS012 | MACXS4</span>
<h2 class="text-base font-bold text-slate-800 dark:text-white">Caxias Norte</h2>
</div>
<p class="text-sm text-slate-500 dark:text-zinc-400 flex items-center gap-1">
<span class="material-symbols-outlined text-sm">location_on</span> Caxias, MA
                        </p><p class="text-[11px] font-medium text-slate-400 dark:text-zinc-500 flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">receipt</span> UC: 54321678</p>
</div>
<button class="p-2 bg-slate-50 dark:bg-zinc-800 rounded-lg text-primary">
<span class="material-symbols-outlined">map</span>
</button>
</div>
<div class="flex gap-2 mt-1">
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary text-white">4G</span>
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary text-white">5G</span>
<span class="ml-auto flex items-center text-xs font-medium px-2 py-0.5 rounded text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20"><span class="w-1.5 h-1.5 rounded-full bg-red-500 mr-1"></span> Desativado</span>
</div>
</div>
</main>
<!-- Bottom Navigation Bar -->
<nav class="fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-lg border-t border-slate-200 dark:border-zinc-800 px-4 pb-6 pt-2 flex items-center justify-around z-50">
<a class="flex flex-col items-center gap-1 text-primary" href="#">
<span class="material-symbols-outlined font-fill text-2xl">list</span>
<span class="text-[10px] font-bold uppercase tracking-wider">Sites</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-zinc-500" href="#">
<span class="material-symbols-outlined text-2xl">map</span>
<span class="text-[10px] font-bold uppercase tracking-wider">Mapa</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-zinc-500" href="#">
<span class="material-symbols-outlined text-2xl">construction</span>
<span class="text-[10px] font-bold uppercase tracking-wider">Tarefas</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-zinc-500" href="#">
<span class="material-symbols-outlined text-2xl">settings</span>
<span class="text-[10px] font-bold uppercase tracking-wider">Ajustes</span>
</a>
</nav>
<!-- Floating Action Button for Scan (Telecom Context) -->
<button class="fixed bottom-24 right-6 bg-primary text-white w-14 h-14 rounded-full shadow-lg shadow-primary/30 flex items-center justify-center z-40 active:scale-90 transition-transform">
<span class="material-symbols-outlined text-3xl">qr_code_scanner</span>
</button>
</div>
</body></html>

<!DOCTYPE html>

<html lang="pt-BR"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Detalhes do Site - São Luís Centro</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f01105",
                        "background-light": "#f8f6f5",
                        "background-dark": "#23100f",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
</head>
<body class="bg-background-light dark:bg-background-dark text-[#1c0d0d] dark:text-white font-display">
<div class="relative flex h-screen w-full flex-col overflow-hidden">
<!-- Top App Bar (Sticky or Over Map) -->
<div class="absolute top-0 left-0 right-0 z-10 flex items-center justify-between p-4 bg-white/80 dark:bg-[#23100f]/80 backdrop-blur-md border-b border-primary/10">
<div class="flex items-center gap-3">
<button class="flex items-center justify-center size-10 rounded-full hover:bg-black/5 dark:hover:bg-white/10 transition-colors">
<span class="material-symbols-outlined text-[#1c0d0d] dark:text-white">arrow_back</span>
</button>
<h2 class="text-[#1c0d0d] dark:text-white text-lg font-bold leading-tight">São Luís Centro</h2>
</div>
<div class="flex gap-2">
<button class="flex items-center justify-center size-10 rounded-full hover:bg-black/5 dark:hover:bg-white/10 transition-colors">
<span class="material-symbols-outlined text-[#1c0d0d] dark:text-white">share</span>
</button>
</div>
</div>
<!-- Scrollable Content Area -->
<div class="flex-1 overflow-y-auto pb-24">
<!-- Map Section (40% height approx) -->
<div class="relative w-full h-[40vh] bg-gray-200 dark:bg-zinc-800">
<div class="w-full h-full bg-center bg-no-repeat bg-cover" data-alt="Google Maps view of Sao Luis city center" data-location="São Luís, Brazil" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuBNJ40bT199Po5s0__2uNJ7TBksEoS6rx3WT2VwiRtPAQCUuuZrXnriwdRF5_zXxg1QiasOxihax0u6uz858-JMazF0tEnHu_uyhHD4GwSr7ZBOHbKumS3H55KWHENONhgnvtbTYPYrKzU3wRHmOHdmToxfRcYmsH4GzRpsjJR_N2geaZuN_sWW094xjEoL06R5ntWq-9QosmBldn-Zn0LsJJI9VtHvhv2RmQ2bpO3yu1TyARN2iHazJahKPtKzIC_CpzBnyt4_ooWb');">
<!-- Custom Red Pin Overlay -->
<div class="absolute inset-0 flex items-center justify-center">
<div class="relative flex flex-col items-center">
<span class="material-symbols-outlined text-primary text-5xl drop-shadow-lg" style="font-variation-settings: 'FILL' 1;">location_on</span>
<div class="absolute -bottom-1 w-2 h-1 bg-black/20 rounded-full blur-[1px]"></div>
</div>
</div>
</div>
<!-- Map Controls Overlay -->
<div class="absolute bottom-4 right-4 flex flex-col gap-2">
<button class="bg-white dark:bg-zinc-900 p-2 rounded-lg shadow-md">
<span class="material-symbols-outlined text-gray-600 dark:text-gray-300">my_location</span>
</button>
</div>
</div>
<!-- Info Section -->
<div class="px-4 pt-6 pb-4 space-y-6">
<!-- Title & Status -->
<div class="flex justify-between items-start">
<div>
<h1 class="text-2xl font-bold text-[#1c0d0d] dark:text-white">São Luís Centro</h1>
<p class="text-sm font-medium text-primary flex items-center gap-1 mt-1">
<span class="size-2 bg-green-500 rounded-full animate-pulse"></span>
                            Site Operacional
                        </p>
</div>
<div class="bg-primary/10 text-primary px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider">
                        ID: SLZ001
                    </div>
</div>
<!-- Main Info Grid -->
<div class="grid grid-cols-1 gap-4">
<!-- Address Card -->
<div class="flex items-center gap-4 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<div class="flex items-center justify-center rounded-lg bg-primary/10 shrink-0 size-12 text-primary">
<span class="material-symbols-outlined">map</span>
</div>
<div class="flex-1">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">Endereço</p>
<p class="text-[#1c0d0d] dark:text-white text-base font-medium leading-snug">Av. Dom Pedro II, Centro, São Luís - MA</p>
</div>
<button class="text-gray-400 hover:text-primary transition-colors">
<span class="material-symbols-outlined">content_copy</span>
</button>
</div>
<div class="grid grid-cols-2 gap-4">
<!-- Coordinates Card -->
<div class="flex flex-col gap-2 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">Coordenadas</p>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary text-sm">explore</span>
<p class="text-[#1c0d0d] dark:text-white text-sm font-medium">-2.529, -44.302</p>
</div>
</div>
<!-- Owner Card -->
<div class="flex flex-col gap-2 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">Proprietário</p>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary text-sm">business_center</span>
<p class="text-[#1c0d0d] dark:text-white text-sm font-medium">ATC</p>
</div>
</div>
</div><div class="grid grid-cols-2 gap-4">
<!-- Sigla Card -->
<div class="flex flex-col gap-2 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">Sigla do Site</p>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary text-sm">tag</span>
<p class="text-[#1c0d0d] dark:text-white text-sm font-medium">MASLS7</p>
</div>
</div>
<!-- UC Card -->
<div class="flex flex-col gap-2 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">UC</p>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary text-sm">electric_bolt</span>
<p class="text-[#1c0d0d] dark:text-white text-sm font-medium">12345678</p>
</div>
</div>
</div>
<!-- Technologies Card -->
<div class="flex flex-col gap-3 bg-white dark:bg-zinc-900 p-4 rounded-xl border border-gray-100 dark:border-white/5 shadow-sm">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight">Tecnologias Disponíveis</p>
<div class="flex flex-wrap gap-2">
<span class="px-3 py-1 bg-primary text-white text-xs font-bold rounded-full">4G</span>
<span class="px-3 py-1 bg-primary/20 text-primary border border-primary/30 text-xs font-bold rounded-full">5G READY</span>
<span class="px-3 py-1 bg-gray-100 dark:bg-white/10 text-gray-600 dark:text-gray-300 text-xs font-bold rounded-full">IOT</span>
</div>
</div>
</div>
<!-- Site Photos (Small carousel style) -->
<div class="space-y-3">
<p class="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-tight px-1">Fotos do Local</p>
<div class="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
<div class="size-24 rounded-lg bg-cover bg-center shrink-0 border border-white/10" data-alt="Telecommunication tower front view" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuCVgZ7EbJDpNs5ZCD1Ztju3w2PdHH3ZscqQT7C38L2mMOlOkmxwOjSENDsw-XWSsU7IJmEX3CAizONNPzNApT7lOcXbyNrGOajhxlxaEjg_bPa0I8uC6fZ8gHVnjY4brys8C4sPmkZPwSLg4J0_bP9VGXxhvYlaSV380JXAp8IgB7P9qYchYnC61tXOMso8vcoybgrfU2Jw6Lnuvb3NqorjbQUWNrEBhBjOnlSP5dtSQ3SfoSa2HOypJoZHZs8fA9vRCoW3cIXxCL4K');"></div>
<div class="size-24 rounded-lg bg-cover bg-center shrink-0 border border-white/10" data-alt="Base station equipment cabin" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuCd08H260gypjP4tkp9gH9Cqu6oZWvYG-fnqn7WZb0GOuHh4jyAtYHqfiLM1Jf_ip4ys9DlalRnSMDhjz1Ybv9tkVOCbVoTX3N3zCPF5P929C_wjy7_noGc2kLgcvF_s_D1HstBIf_BjZj7AOrxKfSX6VD9tb1nxFXVNuAgpzMfUVRV4OruhWvjEYgKyu4NzYx4msiWMllnSHRw1xl71mnx2h2gQH9XA_J1vb7ZK7LTF5iWBhguG8uK0UF21DY-s3-XJn9f0NluJgpW');"></div>
<div class="size-24 rounded-lg bg-cover bg-center shrink-0 border border-white/10" data-alt="Antenna configuration view" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuBJkiz9y7Cvl71ErVpLl9TOWcQngaMHw-bTVtl5tfH4VT2BFrNSRti9xg6k7FdzcJZ46aKa3FEplTLVVmPGf9Eoln_h1fRRKCWjU5YjLqDue7g25YjbPYAxZDVKIzYfsqbbMmmjf6aExUdQQq3sW6IoFBun0Fodo4ok6LjcjZbtWIyYovXj9fu4RSFeGkTbk1A9t1j89Tl1nMitrFJr3iNyAivcowp7zNW2dfuQKmufyoUbvAOiODwomVWgmgDukbomyTOKdPjgFgjL');"></div>
</div>
</div>
</div>
</div>
<!-- Bottom Action Bar -->
<div class="absolute bottom-0 left-0 right-0 p-4 bg-white dark:bg-background-dark border-t border-gray-100 dark:border-white/5">
<button class="w-full h-14 bg-primary hover:bg-red-700 text-white flex items-center justify-center gap-3 rounded-xl font-bold text-sm tracking-wide shadow-lg shadow-primary/20 active:scale-[0.98] transition-all">
<span class="material-symbols-outlined text-xl">directions</span>
                INICIAR ROTA NO GOOGLE MAPS
            </button>
</div>
</div>
</body></html>
