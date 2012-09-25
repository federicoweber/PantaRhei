test:
	mocha -u bdd -t 5000 -R "spec" --compilers coffee:coffee-script

build:
	coffee  -j PantaRhei.js -c src/PantaRhei.coffee src/PantaRhei.workers.coffee
	uglifyjs -o PantaRhei.min.js PantaRhei.js

watch:
	coffee -j PantaRhei.js -c -l  -w src/PantaRhei.coffee src/PantaRhei.workers.coffee

docs:
	docco src/PantaRhei.coffee

.PHONY: test watch build docs