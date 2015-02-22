path = require 'path'

gulp = require 'gulp'
gutil = require 'gulp-util'
rename = require 'gulp-rename'
cached = require 'gulp-cached'
plumber = require 'gulp-plumber'
concat = require 'gulp-concat'
webserver = require 'gulp-webserver'

bower = require 'gulp-bower'
coffee = require 'gulp-coffee'
jade = require 'gulp-jade'
less = require 'gulp-less'
uglify = require 'gulp-uglify'
cssmin = require 'gulp-cssmin'
template = require 'gulp-template-compile'

browserify = require 'browserify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
runSequence = require 'run-sequence'
del = require 'del'


runBrowserify = ->
  browserify
      entries: ['./src/js/main.js']
      debug: true
    .bundle()
    .on 'error', (err) ->
      gutil.log 'Browserify', err.message
      @emit('end')
    .pipe source('main.js')
    .pipe buffer()

runLess = ->
  gulp.src 'src/css/*.less'
    .pipe plumber()
    .pipe cached('less')
    .pipe less
      paths: [ path.join(__dirname, 'bower_components/bootstrap/less') ]

runJade = (debug = true) ->
  gulp.src 'src/*.jade'
    .pipe plumber()
    .pipe cached('jade')
    .pipe jade
      locals:
        debug: debug

runJadeTemplate = (debug = true) ->
  gulp.src 'src/views/*.jade'
    .pipe plumber()
    .pipe cached('jade-tmpl')
    .pipe jade
      locals:
        debug: debug
    .pipe template()

  
gulp.task 'browserify', ->
  runBrowserify()
    .pipe gulp.dest 'dist/js/'

gulp.task 'browserify-prod', ->
  runBrowserify()
    .pipe uglify()
    .pipe rename( suffix: '.min')
    .pipe gulp.dest 'dist/js/'


gulp.task 'coffee', ->
  gulp.src 'src/**/*.coffee'
    .pipe plumber()
    .pipe cached('coffee')
    .pipe coffee( bare: true )
    .pipe rename( extname: '.js' )
    .pipe gulp.dest('src/')

    
gulp.task 'less', ->
  runLess()
    .pipe gulp.dest('dist/css/')

gulp.task 'less-prod', ->
  runLess()
    .pipe cssmin()
    .pipe rename( suffix: '.min' )
    .pipe gulp.dest('dist/css/')


gulp.task 'jade', ->
  runJade()
    .pipe gulp.dest('dist/')

gulp.task 'jade-prod', ->
  runJade(false)
    .pipe gulp.dest('dist/')


gulp.task 'jade-tmpl', ->
  runJadeTemplate()
    .pipe concat('views.js')
    .pipe gulp.dest('src/js/')

gulp.task 'jade-tmpl-prod', ->
  runJadeTemplate(false)
    .pipe concat('views.js')
    .pipe gulp.dest('src/js/')


gulp.task 'vendor', ->
  gulp.src 'src/vendor/**/*'
    .pipe cached('vendor')
    .pipe gulp.dest('dist/')

gulp.task 'vendor-prod', ['vendor-prod-css'], ->
  gulp.src ['src/vendor/**/*', '!src/vendor/**/*.css']
    .pipe gulp.dest('dist/')

gulp.task 'vendor-prod-css', ->
  gulp.src 'src/vendor/**/*.css'
    .pipe cssmin()
    .pipe rename( suffix: '.min' )
    .pipe gulp.dest('dist/')

# -----------------------------------------------------------------------------

gulp.task 'bower', ->
  bower( cmd: 'install')

gulp.task 'clean', (cb) ->
  del(['src/js/**/*.js'], cb)

gulp.task 'webserver', ->
  gulp.src 'dist'
    .pipe webserver
#      host: 'yurie-local.pine.moe'
      livereload: true
      open: false
#      https: true

gulp.task 'default', (cb) ->
  runSequence(
    'clean',
    ['jade-tmpl', 'coffee'],
    ['jade', 'less', 'vendor','browserify'],
    cb)
  
gulp.task 'build', (cb) ->
  runSequence(
    'clean',
    ['jade-tmpl-prod', 'coffee'],
    ['jade-prod', 'less-prod', 'vendor-prod', 'browserify-prod'],
    cb)
  
gulp.task 'watch', (cb) ->
  runSequence 'default', ->
    gulp.watch ['src/js/**/*.js'], ['browserify']

    gulp.watch 'src/js/**/*.coffee', ['coffee']
    gulp.watch 'src/css/**/*.less', ['less']
    gulp.watch 'src/*.jade', ['jade']

    gulp.watch 'src/vendor/**/*', ['vendor']
    gulp.watch 'src/views/**/*.jade', ['jade-tmpl']
    
    cb()
  