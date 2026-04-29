document.addEventListener("DOMContentLoaded", () => {
  const proof = document.getElementById("script-proof");
  if (proof) {
    proof.textContent = "Local JavaScript loaded from assets/proof.js";
    proof.classList.add("js-proof");
  }

  const stamp = document.getElementById("loaded-at");
  if (stamp) {
    stamp.textContent = "Client-side script confirmed";
  }

  document.body.classList.add("js-ready");
});
