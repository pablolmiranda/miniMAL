STEPS = step1_read_print step2_eval step3_env step4_if_fn_do step5_tco \
        step6_file step7_quote step8_macros step9_try stepA_interop \
        stepB_web stepB_node stepB_js1k

.SECONDARY:

all: miniMAL-min.js miniMAL-js1k.js miniMAL-node.js

#
# Uglify
#
UGLIFY_OPTS=-c hoist_funs=true,unsafe=true,keep_fargs=true,pure_getters=true,screw-ie8=true,unused=false -m -e

REGPACK_OPTS=--crushGainFactor 2 --crushLengthFactor 1 --crushCopiesFactor 0
#REGPACK_OPTS=--crushGainFactor 1 --crushLengthFactor 0 --crushCopiesFactor 0

node_modules/uglify-js:
	npm install

%-uglify-pretty.js: %.js node_modules/uglify-js
	node_modules/uglify-js/bin/uglifyjs $< -b $(UGLIFY_OPTS) | sed 's/^!function() *{\(.*\)}();/\1/' > $@

%-uglify.js: %.js node_modules/uglify-js
	node_modules/uglify-js/bin/uglifyjs $<    $(UGLIFY_OPTS) | sed 's/^!function() *{\(.*\)}();/\1/' > $@

#
# JsCrush
#
node_modules/jscrush:
	npm install

%-crush.js: %-uglify.js node_modules/jscrush
	cat $< | node_modules/jscrush/bin/jscrush > $@

crush^%: %-crush.js
	@true

#
# RegPack
#
RegPack/node_modules/minimist:
	cd RegPack && npm install

%-regpack.js: %-uglify.js RegPack/node_modules/minimist
	node ./RegPack/regPack.js $(REGPACK_OPTS) $< > $@

regpack^%: %-regpack.js
	@true

#
# Stats
#
stats^%: %.js %-uglify.js %-crush.js %-regpack.js
	@wc $^ | grep -v "total"

#
# Web
#
miniMAL-min.js: stepB_web-regpack.js
	cp $< $@

miniMAL-js1k.js: stepB_js1k-regpack.js
	cp $< $@

miniMAL-js1k.b64: stepB_js1k-regpack.js
	node -e "console.log(require('fs').readFileSync('$<').toString('base64'))" > $@

#
# Node
#
miniMAL-node.js: stepB_node-regpack.js
	cp $< $@

.PHONY: crush regpack stats clean
crush: $(foreach s,$(STEPS),crush^$(s))
regpack: $(foreach s,$(STEPS),regpack^$(s))
stats: $(foreach s,$(STEPS),stats^$(s))

clean:
	rm -f *-uglify.js *-uglify-pretty.js *-crush.js *-regpack.js
