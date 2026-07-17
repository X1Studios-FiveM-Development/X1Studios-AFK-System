const box = document.getElementById("afkBox");
const line3 = document.getElementById("line3");
const btn = document.getElementById("backBtn");

window.addEventListener("message", function(event) {
    const data = event.data;

    if (data.action === "show") {
        box.style.display = "block";
        line3.innerText = data.time + " Minutes";
    }

    if (data.action === "hide") {
        box.style.display = "none";
    }

    if (data.action === "update") {
        line3.innerText = data.time + " Minutes";
    }
});

btn.onclick = function() {
    fetch(`https://${GetParentResourceName()}/back`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({})
    });
};
