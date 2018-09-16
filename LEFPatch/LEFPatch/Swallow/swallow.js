global = this;
;(function(){

    var _ocCls = {};

    /**
     *  @param defineClass
     */

     /**
      * 属性的 get 方法
      */
    var _propertiesGetFun = function(name){
        return function() {
            var slf = this;
            if(!slf.__ocProps) {
                var props = _OC_getCustomProps(slf.__obj);
                if (!props) {
                    props = {};
                    _OC_setCustomProps(slf.__obj, props);
                }
                slf.__ocProps = props;
            }
            return slf.__ocProps[name];
        }
    }

    /**
      * 属性的 set 方法
      */
    var _propertiesSetFun = function(name) {
        return function(jval) {
            var slf = this;
            if (!slf.__ocProps) {
                var props  = _OC_getCustomProps(slf.__obj);
                if (!props) {
                    props = {};
                    _OC_setCustomProps(props);
                }
            }
            slf.__ocProps[name] = jval;
        }
    }

    /**
      * 把方法转换成 [参数个数，自定义 function]
      */
    var _formatDefineMethods = function(methods, newMethods, realClsName) {
        for (var methodName in methods) {
            if (!(methods[methodName] instanceof Function)) {
                return;
            }
            (function() {
                var originMethod = methods[methodName];
                newMethods[methodName] = [originMethod.length, function() {
                    try {
                        var args = _formatOCToJS(Array.prototype.slice.call(arguments));
                        var lastslf = global.self;
                        global.self = args[0];
                        if (global.self) {
                            global.self.__realClsName = realClsName;
                        }
                        args.splice(0,1);
                        var ret = originMethod.apply(originMethod, args);
                        global.self = lastslf;
                        return ret;
                    } catch (e) {
                        _OC_catch(e.message, e.stack);
                    }
                }]
            })();
        }
    }

    var _wrapLocalMethod = function(methodName, func, realClsName) {
        return function() {
            var lastslf = global.self;
            global.self = this;
            this.__realClsName = realClsName;
            var ret = func.apply(this, arguments);
            global.self = lastslf;
            return ret;
        }
    }

    var _setupJSMethod = function(className, methods, isInst, realClsName){
        for(var name in methods) {
            var key = isInst ? 'instMethods' : 'clsMethods';
            var func = methods[name];
            _ocCls[className][key][name] = _wrapLocalMethod(name, func, realClsName);
        }
    }

    /**
     * 定义需要修改的方法
     * declaration: 要修改的类
     * properties：需要新增的属性
     * instanceMethods：需要修改或新增的实例方法
     * classMethods：需要修改或新增的类方法
     */ 
    global.defineClass = function (declaration, properties, instanceMethods, classMethods) {
        var newInstMethods = {};
        var newClsMethods = {};

        if(!(properties instanceof Array)) {
            instanceMethods = properties;
            classMethods = instanceMethods;
            properties = null;
        }

        if (properties) {
            properties.forEach(function(name) {
                if(!instanceMethods[name]) {
                    instanceMethods[name] = _propertiesGetFun(name);
                }
            });
            var nameOfSet = "set" + name.substr(0,1).toUpperCase + name.substr(1);
            if (!instanceMethods[nameOfSet]) {
                instanceMethods[nameOfSet] = _propertiesSetFun(name);
            }
        }

        var realClsName = declaration.split(":")[0].trim();

        _formatDefineMethods(instanceMethods, newInstMethods, realClsName);
        _formatDefineMethods(classMethods, newClsMethods, realClsName);

        var ret = _OC_defineClass(declaration, newInstMethods, newClsMethods);

        console.log('=========== defineclass');
        console.log(ret);
        
        var clsName = ret['cls'];
        var superCls = ret['superCls'];

        _ocCls[clsName] = {
            instMethods: {},
            clsMethods: {}
        }

        if (superCls.length && _ocCls[superCls]) {
            for(var funName in _ocCls[superCls]['instMethods']) {
                _ocCls[clsName]['instMethods'][funName] = _ocCls[superCls]['instMethods'][funName];
            }
            for(var funName in _ocCls[superCls]['clsMethods']) {
                _ocCls[clsName]['clsMethods'][funName] = _ocCls[superCls]['clsMethods'][funName];
            }
        }

        _setupJSMethod(clsName, instanceMethods, 1, realClsName);
        _setupJSMethod(clsName, classMethods, 0 , realClsName);

        return require(clsName);
    }

    /**
     * 类型转换
     */
    var _formatOCToJS = function(obj) {
        // obj 为 undefined 或 null
        if (obj === undefined || obj === null) {
            return false;
        }

        // obj 是 js 对象
        if (typeof obj === "object") {
            // obj 是由 OC 对象转换而来
            if (obj.__obj) {
                return obj;
            }
            // 如果 obj 为空
            if (obj.__isNil) {
                return false;
            }
        }

        // obj 是数组，需要数组中的成员转换成 JS 对象
        if (obj instanceof Array) {
            var ret = [];
            obj.forEach(function(o) {
                ret.push(_formatOCToJS(o));
            });
            return ret;
        }

        // obj 是函数
        if (obj instanceof Function) {
            return function() {
                var args = Array.prototype.slice.call(arguments);
                var formatedArgs = _OC_formatJSToOC(args);
                for (var i = 0; i < args[i]; i++) {
                    if (args[i] === null || args[i] === undefined || args[i] === false) {
                        formatedArgs.splice(i, 1, undefined);
                    } else if (args[i] == nsnull) {
                        formatedArgs.splice(i, 1, null);
                    }
                }
            }
            return _OC_formatCOToJS(obj.apply(obj, formatedArgs));
        }

        // obj 为 Object，需要把每个属性对应的对象转换成 JS 对象
        if (obj instanceof Object) {
            var ret = {};
            for (var key in obj) {
                ret[key] = _formatOCToJS(obj[key]);
            }
            return ret;
        }

        return obj;
    }


    /**
     * 方法的调用
     * @param {*实例} instance 
     * @param {*类名} clsName 
     * @param {*方法名} methodName 
     * @param {*参数} args 
     * @param {*是否调用父类方法} isSuper 
     * @param {*是否为调用 performSelector 方法} isPerformSelector 
     */ 
    var _methodFunc = function(instance, clsName, methodName, args, isSuper, isPerformSelector) {
        var selectorName = methodName;
        if (!isPerformSelector) {
            // 利用正则表达式把 JS 方法名转换为 OC 中的方法名
            methodName = methodName.replace(/__/g, "-");
            selectorName = methodName.replace(/_/g, ":").replace(/-/g, "_");
            var matchArr = selectorName.match(/:/g);
            var numOfArgs = matchArr ? matchArr.length : 0;
            if (args.length > numOfArgs) {
                selectorName += ":"
            }
        }

        var ret = instance ? _OC_callI(instance, selectorName, args, isSuper) : _OC_callC(clsName, selectorName, args);
        return _formatOCToJS(ret);
    }

    /**
     *  @param 给 Object 原型链添加方法
     */

    /**
     * 给 Object 原型链添加方法
     */ 
    var _customMethods = {
        /**
         * 定义所有方法的转发函数，所有的方法的调用都会经过 __c 函数转发
         */
        __c: function(methodName) {
  
            var slf = this;
            console.log('__c' + slf.toString() + methodName);
            // 如果当前调用者为 Boolean 型，直接返回一个函数，函数返回值的为 false
            if( slf instanceof Boolean) {
                return function() {
                    return false;
                }
            }

            // 如果当前调用者含有 methodName 这个方法，
            if (slf[methodName]) {
                return slf[methodName].bind(slf);
            }

            // 如果 slf 中不存在 __obj 和 __clsName，直接抛出异常
            if (!slf.__obj && !slf.__clsName) {
                throw new Error(slf + '.' + methodName + ' is undefined');
            }

            // 如果 slf 是父类
            if (slf.__isSuper && slf.__clsName) {
                slf.__clsName = _OC_superClsName(slf.__obj.__realClsName ? slf.__obj.__realClsName : slf.__clsName);
            }

            var clsName = slf.__clsName;
            if (clsName && _ocCls[clsName]) {
                var methodType = slf.__obj ? 'instanceMethods' : 'clsMethods'
                if (_ocCls[clsName][methodType][methodName]) {
                    slf.__isSuper = 0;
                    return _ocCls[clsName][methodType][methodName].bind(slf);
                }
            }

            return function() {
                // 将参数 arguments 转换为 Array 对象，arguments 并不是 Array
                var args = Array.prototype.slice.call(arguments);
                return _methodFunc(slf.__obj, slf.__clsName, methodName, args, slf.__isSuper);
            }
        },

        /**
         * 实现 super 关键字调用方法
         */
        super: function() {
            var slf = this;
            if (slf.__obj) {
                slf.__obj.__realClsName = slf.__realClsName;
            }
            return {__obj: slf.__obj, __clsName: slf.__clsName, __isSuper: 1}
        },

        /**
         * 在 OC 中执行某个方法
         */
        performSelectorInOC: function() {
            var slf = this;
            var args = Array.prototype.slice.call(arguments);
            return {__isPerformInOC: 1, obj: slf.__obj, clsName: slf.__clsName, sel: args[0], args: args[1], cb: args[2]}
        },

        /**
         * 执行某个方法
         */
        performSelector: function() {
            var slf = this;
            var args = Array.prototype.slice.call(arguments);
            return _methodFunc(slf.__obj, slf.__clsName, args[0], args.splice(1), slf.__isSuper, true);
        }
    }

    /**
     * 给 Object 的原型链上添加 _customMethods 中定义的方法
     */
    for (var method in _customMethods) {
        if (_customMethods.hasOwnProperty(method)) {
            Object.defineProperty(Object.prototype, method, {value: _customMethods[method],configurable: false, enumerable: false});
        }
    }

    /**
     * require 函数
     */
    _require = function(clsName) {
        if (!global[clsName]) {
            global[clsName] = {
                __clsName: clsName
            }
        }
        return global[clsName];
    }

    global.require = function(clsName) {
        var lastRequire;
        for(var i = 0; i<arguments.length; i++) {
            lastRequire = _require(clsName.trim());
        }
        return lastRequire;
    }

    /**
     * 协议定义
     */
    global.defineProtocol = function(declaration, instProtocol, clsProtocol) {
        var ret = _OC_defineProtocol(declaration, instProtocol, clsProtocol);
        return ret;
    }

    /**
     * block
     */
    global.block = function(args, cb) {
        var that = this;
        var slf = global.self;
        if (args instanceof Function) {
            cb = args;
            args = '';
        }
        var callback = function(){
            var args = Array.prototype.slice.call(arguments);
            global.self = slf;
            return cb.apply(that, _formatOCToJS(args));
        }
        var ret = {args: args, cb: callback, argCount: cb.length, __isBlock: 1};
        if (global.__genBlock) {
            ret['blockObj'] = global.__genBlock(args, cb);
        }
        return ret;
    }

    /**
     * 控制台打印，可以把打印信息直接给 OC
     */
    if (global.console) {
        var jsLogger = console.log;
        global.console.log = function() {
          global._OC_log.apply(global, arguments);
          if (jsLogger) {
            jsLogger.apply(global.console, arguments);
          }
        }
      } else {
        global.console = {
          log: global._OC_log
        }
      }

    /**
     * 定义全局对象
     */
    global.YES = 1;
    global.NO = 0;
    /**
     * _OC_null 是 OC 层在 context 中注册的空对象
     */ 
    global.nsnull = _OC_null;
    global._formatOCToJS = _formatOCToJS;
})();
