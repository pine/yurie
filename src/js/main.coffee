_ = require 'lodash'
Vue = require 'vue'

# JST を読み込む
# JST 内で Lo-dash を使うので、事前にグローバルへ定義しておく
window._ = _
require './views'


# メニューバーのアニメーション処理
setupHeadroom = ->
  $('.headroom').headroom
    tolerance: 20
    offset: 50
    classes:
      initial: "animated"
      pinned: "slideDown"
      unpinned: "slideUp"

$ ->
  setupHeadroom()


# メイン VM を読み込む
new Vue require('./vm/main')