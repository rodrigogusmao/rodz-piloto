/* =======================================================================================
   rodz-piloto :: NUI tablet (vanilla JS) — referência visual mri-ui-kit
   ======================================================================================= */
(function () {
    "use strict";

    var RES = "rodz-piloto";
    var profile = null;          // payload vindo do server (getProfile + mission)
    var selectedPlane = null;    // modelo de avião escolhido pelo jogador

    // ---------- helpers ----------
    function $(id) { return document.getElementById(id); }
    function show(el) { if (el) el.classList.remove("hidden"); }
    function hide(el) { if (el) el.classList.add("hidden"); }
    function svg(id) { return '<svg class="icon" aria-hidden="true"><use href="#' + id + '"/></svg>'; }

    function money(v) {
        v = Math.floor(Number(v) || 0);
        return "R$ " + v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    }

    function post(name, data) {
        try {
            fetch("https://" + RES + "/" + name, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: JSON.stringify(data || {})
            }).catch(function () {});
        } catch (e) { /* fora do jogo */ }
    }

    // ---------- abrir / fechar ----------
    function openTablet(data) {
        profile = data || {};
        // escolher por padrão o melhor avião liberado
        selectedPlane = null;
        if (profile.planes) {
            for (var i = 0; i < profile.planes.length; i++) {
                if (!profile.planes[i].locked) selectedPlane = profile.planes[i].model;
            }
        }
        show($("app"));
        try {
            renderAll();
        } catch (e) {
            console.error("[rodz-piloto] erro ao renderizar tablet:", e);
        }
    }

    function closeTablet(silent) {
        hide($("app"));
        if (!silent) post("closeTablet");
    }

    // ---------- navegação de abas ----------
    function switchTab(tab) {
        var btns = document.querySelectorAll(".nav-btn");
        for (var i = 0; i < btns.length; i++) {
            btns[i].classList.toggle("active", btns[i].getAttribute("data-tab") === tab);
        }
        var secs = document.querySelectorAll(".tab-section");
        for (var j = 0; j < secs.length; j++) {
            secs[j].classList.toggle("hidden", secs[j].id !== "tab-" + tab);
        }
    }

    // ---------- render ----------
    function renderAll() {
        if (!profile) return;
        renderSidebar();
        renderDashboard();
        renderRoutes();
        renderPlanes();
        renderShop();
        renderHistory();
    }

    function renderSidebar() {
        $("sidebar-level-badge").textContent = "Nv. " + profile.level;
        $("sidebar-level-title").textContent = profile.levelLabel || "";
        $("sidebar-xp-fill").style.width = (profile.xpProgress || 0) + "%";
        $("sidebar-xp-text").innerHTML = "<span>" + (profile.xp || 0) + " XP</span><span>" +
            (profile.xpToNext > 0 ? "+" + profile.xpToNext : "MAX") + "</span>";
    }

    function renderDashboard() {
        $("profile-level-num").textContent = profile.level;
        $("profile-level-label").textContent = profile.levelLabel || "";
        $("profile-xp").textContent = profile.xp || 0;
        $("profile-xp-next").textContent = profile.nextLevelXP || 0;
        $("xp-fill").style.width = (profile.xpProgress || 0) + "%";

        $("stat-deliveries").textContent = profile.totalDeliveries || 0;
        $("stat-earned").textContent = money(profile.totalEarned);
        $("stat-xp").textContent = profile.xp || 0;
        $("stat-mult").textContent = "x" + (profile.multiplier || 1).toFixed(2);

        // rota ativa
        var card = $("active-job-card");
        if (profile.mission && profile.mission.phase && profile.mission.phase !== "completed") {
            var m = profile.mission;
            var dest = (m.destination && m.destination.name) || "—";
            $("active-job-info").textContent =
                "Destino: " + dest + " · Caixas: " + (m.boxesDelivered || 0) + "/" + (m.boxesRequired || 0);
            show(card);
        } else {
            hide(card);
        }

        // grade de níveis
        var grid = $("levels-grid");
        grid.innerHTML = "";
        (profile.levels || []).forEach(function (lv) {
            var n = lv.level;
            var cls = "level-item";
            if (n === profile.level) cls += " current";
            else if (n > profile.level) cls += " locked";
            var div = document.createElement("div");
            div.className = cls;
            div.innerHTML =
                '<div class="level-num" style="color:' + (lv.color || "#fff") + '">' + n + '</div>' +
                '<div class="level-name">' + (lv.label || "") + '</div>' +
                '<div class="level-mult">x' + (lv.multiplier || 1).toFixed(2) + '</div>' +
                '<div class="level-xp">' + lv.xp + ' XP</div>';
            grid.appendChild(div);
        });
    }

    function renderRoutes() {
        // banner de brevê
        if (profile.hasLicense) hide($("no-license-banner"));
        else show($("no-license-banner"));

        var list = $("route-list");
        list.innerHTML = "";

        var hasActive = profile.mission && profile.mission.phase && profile.mission.phase !== "completed";

        // Destinos
        (profile.destinations || []).forEach(function (d) {
            var levelLocked = d.locked;
            var locked = levelLocked || hasActive || !profile.hasLicense;
            var card = document.createElement("div");
            card.className = "route-card" + (locked ? " locked" : "");
            var lockTag = levelLocked ? '<span class="tag-lock">' + svg("icon-lock") + ' Nível ' + d.minLevel + '</span>'
                : (!profile.hasLicense ? '<span class="tag-lock">' + svg("icon-lock") + ' Brevê</span>' : '');
            card.innerHTML =
                '<div class="route-info">' +
                    '<div class="route-name">' + svg("icon-map") + ' ' + d.name + ' ' + lockTag + '</div>' +
                    '<div class="route-meta">' +
                        '<span>Nível mín.: ' + d.minLevel + '</span>' +
                        '<span>' + svg("icon-star") + ' ' + d.baseXP + ' XP/caixa</span>' +
                    '</div>' +
                '</div>' +
                '<div class="route-right">' +
                    '<div class="route-pay">' + money(d.payMin) + '–' + money(d.payMax) + '</div>' +
                    '<div class="route-xp">por caixa</div>' +
                '</div>';
            if (!locked) {
                card.addEventListener("click", function () {
                    post("startRoute", { destinationIndex: d.index, planeModel: selectedPlane });
                    closeTablet();
                });
            }
            list.appendChild(card);
        });
    }

    function renderPlanes() {
        // card de devolução
        var rc = $("plane-return-card");
        if (profile.hasPlane) {
            rc.classList.add("has-plane");
            $("plane-return-desc").textContent = "Você tem uma aeronave em uso.";
            $("btn-return-plane").disabled = false;
        } else {
            rc.classList.remove("has-plane");
            $("plane-return-desc").textContent = "Nenhuma aeronave em uso.";
            $("btn-return-plane").disabled = true;
        }

        var list = $("planes-list");
        list.innerHTML = "";
        (profile.planes || []).forEach(function (p) {
            var card = document.createElement("div");
            var cls = "rent-card";
            if (p.locked) cls += " locked";
            else if (p.model === selectedPlane) cls += " selected";
            card.className = cls;
            var right;
            if (p.locked) {
                right = '<span class="tag-lock">' + svg("icon-lock") + ' Nível ' + p.minLevel + '</span>';
            } else if (p.model === selectedPlane) {
                right = '<button class="btn-primary rent-btn" disabled>' + svg("icon-check") + ' Selecionada</button>';
            } else {
                right = '<button class="btn-secondary rent-btn" data-plane="' + p.model + '">Selecionar</button>';
            }
            var imgSrc = p.image ? (p.image.indexOf("http") === 0 ? p.image : "img/planes/" + p.image) : "";
            var thumb = imgSrc
                ? '<div class="rent-thumb"><img src="' + imgSrc + '" onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'flex\'"><svg class="rent-thumb-fb" style="display:none"><use href="#icon-jet"/></svg></div>'
                : '<div class="rent-thumb"><svg class="rent-thumb-fb" style="display:flex"><use href="#icon-jet"/></svg></div>';
            card.innerHTML =
                thumb +
                '<div class="rent-info">' +
                    '<div class="rent-name">' + p.label + ' <span style="color:var(--color-muted-fg);font-weight:400;font-size:11px">· ' + p.speed + '</span></div>' +
                    '<div class="rent-desc">' + p.desc + '</div>' +
                '</div>' + right;
            list.appendChild(card);
        });

        // listeners de seleção
        var btns = list.querySelectorAll("[data-plane]");
        for (var i = 0; i < btns.length; i++) {
            btns[i].addEventListener("click", function (e) {
                selectedPlane = e.currentTarget.getAttribute("data-plane");
                renderPlanes();
            });
        }
    }

    function renderShop() {
        $("shop-license-price").textContent = money(profile.licensePrice);
        $("shop-parachute-price").textContent = money(profile.parachutePrice);
        var licenseCard = $("btn-buy-license").closest(".shop-card");
        if (profile.hasLicense) {
            licenseCard.classList.add("owned");
            $("btn-buy-license").textContent = "Adquirido";
        } else {
            licenseCard.classList.remove("owned");
            $("btn-buy-license").textContent = "Comprar";
        }
    }

    function renderHistory() {
        var list = $("history-list");
        list.innerHTML = "";
        var hist = profile.history || [];
        if (hist.length === 0) {
            list.innerHTML = '<div class="empty-state">Nenhuma entrega registrada ainda.</div>';
            return;
        }
        hist.forEach(function (h) {
            var item = document.createElement("div");
            item.className = "history-item";
            var tag = h.special ? " · Especial" : (h.clandestine ? " · Clandestina" : "");
            item.innerHTML =
                '<svg class="history-icon" aria-hidden="true"><use href="#icon-package"/></svg>' +
                '<div class="history-info">' +
                    '<div class="history-route">' + (h.destination || "—") + tag + '</div>' +
                    '<div class="history-cargo">' + (h.boxes || 0) + ' caixa(s)</div>' +
                '</div>' +
                '<div class="history-right">' +
                    '<div class="history-pay">' + money(h.pay) + '</div>' +
                    '<div class="history-xp">+' + (h.xp || 0) + ' XP</div>' +
                    '<div class="history-date">' + (h.date || "") + '</div>' +
                '</div>';
            list.appendChild(item);
        });
    }

    // ---------- HUD ----------
    function updateHUD(data) {
        var hud = $("job-hud");
        if (!data || !data.show) { hide(hud); return; }
        $("hud-route").textContent = data.route || "—";
        $("hud-cargo").textContent = (data.delivered || 0) + "/" + (data.required || 0);
        $("hud-phase").textContent = data.phase || "";
        show(hud);
    }

    // ---------- eventos de UI ----------
    function bindUI() {
        var navs = document.querySelectorAll(".nav-btn");
        for (var i = 0; i < navs.length; i++) {
            navs[i].addEventListener("click", function (e) {
                switchTab(e.currentTarget.getAttribute("data-tab"));
            });
        }
        $("close-btn").addEventListener("click", function () { closeTablet(); });
        $("btn-buy-license").addEventListener("click", function () { post("buyLicense"); });
        $("btn-buy-parachute").addEventListener("click", function () { post("buyParachute"); });
        $("btn-go-shop").addEventListener("click", function () { switchTab("shop"); });
        $("btn-clandestine").addEventListener("click", function () {
            post("startClandestine", { planeModel: selectedPlane }); closeTablet();
        });
        $("btn-return-plane").addEventListener("click", function () { post("returnPlane"); });
        $("btn-cancel-job-dash").addEventListener("click", function () { post("cancelMission"); });

        document.addEventListener("keyup", function (e) {
            if ((e.key === "Escape" || e.key === "Esc") && !$("app").classList.contains("hidden")) {
                closeTablet();
            }
        });
    }

    // ---------- mensagens do client ----------
    window.addEventListener("message", function (event) {
        var d = event.data || {};
        if (d.action === "open") {
            openTablet(d.profile);
        } else if (d.action === "close") {
            closeTablet(true);
        } else if (d.action === "updateProfile") {
            profile = d.profile || profile;
            renderAll();
        } else if (d.action === "hud") {
            updateHUD(d);
        }
    });

    bindUI();
})();
