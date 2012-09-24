test:
	mocha -u bdd -t 5000 -R "spec" --compilers coffee:coffee-script

build:
	coffee -c -o src/.. src/PantaRhei.coffee 
	uglifyjs -o PantaRhei.min.js PantaRhei.js

watch:
	coffee -c -l -o src/.. -w src/PantaRhei.coffee

docs:
	docco src/PantaRhei.coffee

.PHONY: test watch build docs