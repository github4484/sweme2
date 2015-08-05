class Expression {
    func toString() -> String { return "#E" }
}

class Nil : Expression {
    override func toString() -> String {
        return "#N"
    }
}

class Symbol : Expression {
    let name: String
    init(name: String){
        self.name = name
    }
    
    override func toString() -> String {
        return "symbol(" + self.name + ")"
    }
}

class Boolean : Expression {
    let value: Bool
    init(value: Bool) {
        self.value = value
    }

    override func toString() -> String {
        return self.value ? "#T" : "#F"
    }
}

class Number : Expression {
    let value: Int
    init(value: Int) {
        self.value = value
    }
    override func toString() -> String {
        return String(self.value)
    }
}

class List : Expression {
    var es: [Expression] = [] // es stands for ElementS
    
    init(es: [Expression]) {
        self.es = es
    }

    override func toString() -> String {
        return "(" + join(" ", map(es) { $0.toString() }) + ")"
    }
}

class Procedure : Expression {
    var params: List
    var body: List
    var lexicalEnv: Environment

    init(params: List, body: List, lexicalEnv: Environment){
        self.params = params
        self.body = body
        self.lexicalEnv = lexicalEnv
    }

    override func toString() -> String {
        return "\\(\(params.toString()) \(body.toString()))"
    }
}