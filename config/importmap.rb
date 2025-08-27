# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

pin "axios", to: "https://cdn.jsdelivr.net/npm/axios@1.6.0/dist/axios.min.js"
pin "howler", to: "https://cdn.jsdelivr.net/npm/howler/+esm"
# EasyMDE loaded globally via script tag in layout