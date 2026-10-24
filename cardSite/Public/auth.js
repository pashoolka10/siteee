// ============================================================
// Всплывающее окно входа/регистрации (п.5 лабораторной)
// ============================================================

// Показать модалку. isError = true — сообщение об ошибке (красная плашка)
function showAuthModal(message, mode, isError) {
    var modal = document.getElementById("authModal");
    if (!modal) return;

    var msg = document.getElementById("authMessage");
    if (message) {
        msg.textContent = message;
        msg.hidden = false;
        if (isError) {
            msg.classList.add("auth-modal__message_error");
        } else {
            msg.classList.remove("auth-modal__message_error");
        }
    } else {
        msg.hidden = true;
    }

    switchAuthTab(mode === "register" ? "register" : "login");
    modal.hidden = false;
}

// Скрыть модалку
function hideAuthModal() {
    var modal = document.getElementById("authModal");
    if (modal) modal.hidden = true;
}

// Переключить вкладку
function switchAuthTab(name) {
    var loginForm    = document.getElementById("authLoginForm");
    var registerForm = document.getElementById("authRegisterForm");
    var loginTab     = document.getElementById("tabLogin");
    var registerTab  = document.getElementById("tabRegister");
    var title        = document.getElementById("authTitle");

    if (!loginForm) return;

    if (name === "register") {
        loginForm.hidden = true;
        registerForm.hidden = false;
        loginTab.classList.remove("auth-modal__tab_active");
        registerTab.classList.add("auth-modal__tab_active");
        title.textContent = "Регистрация";
    } else {
        loginForm.hidden = false;
        registerForm.hidden = true;
        loginTab.classList.add("auth-modal__tab_active");
        registerTab.classList.remove("auth-modal__tab_active");
        title.textContent = "Вход";
    }
}


window.addEventListener("DOMContentLoaded", function () {
    var params = new URLSearchParams(window.location.search);

    var error = params.get("error");
    if (error) {

        showAuthModal(error, params.get("tab") === "register" ? "register" : "login", true);
        return;
    }

    var message = params.get("message");
    if (message) {
        showAuthModal(message, "login");
        return;
    }

    var needAuth = params.get("need_auth");
    if (needAuth === "cart") {
        showAuthModal("Войдите или зарегистрируйтесь для просмотра корзины", "login");
    } else if (needAuth === "add") {
        showAuthModal("Войдите или зарегистрируйтесь для добавления в корзину", "login");
    } else if (needAuth) {
        showAuthModal("Войдите или зарегистрируйтесь", "login");
    }
});
