import Foundation

enum MathContent {
    private static let baseLessons: [Lesson] = [
        Lesson(id: "p-number-sense", title: "心算闪电脑", ability: "数感雷达", subject: .math, stage: .primary, minutes: 8, summary: "用拆分和凑整，让计算变成一条捷径。", questions: [Question(id: "p1", prompt: "48 × 25 = ?", kind: .choice, choices: [QuestionChoice(id: "1200", text: "1200"), QuestionChoice(id: "1000", text: "1000"), QuestionChoice(id: "960", text: "960")], answer: "1200", explanation: "25 × 4 = 100，再把 48 拆成 4 × 12。")]),
        Lesson(id: "p-fraction", title: "分数披萨店", ability: "分数直觉", subject: .math, stage: .primary, minutes: 7, summary: "比较分数大小，建立整体与部分的感觉。", questions: []),
        Lesson(id: "p-pattern", title: "规律侦探社", ability: "找规律", subject: .math, stage: .primary, minutes: 6, summary: "从数字变化中找到下一步线索。", questions: []),
        Lesson(id: "j-equation", title: "方程解锁室", ability: "代数思维", subject: .math, stage: .junior, minutes: 10, summary: "把未知数当成线索，逐步还原答案。", questions: []),
        Lesson(id: "j-function", title: "函数发射台", ability: "变化关系", subject: .math, stage: .junior, minutes: 10, summary: "读懂两个量如何一起变化。", questions: []),
        Lesson(id: "j-probability", title: "概率抽签局", ability: "可能性", subject: .math, stage: .junior, minutes: 8, summary: "用实验和直觉理解概率。", questions: [])
    ] + extendedLessons
    private static let extendedLessons: [Lesson] = [
        lesson("p-place", "数位与大数", "数与运算", .primary, "读写大数、近似数和数的改写"), lesson("p-four", "四则运算", "数与运算", .primary, "整数、小数四则混合运算"), lesson("p-decimal", "小数世界", "数与运算", .primary, "小数意义、性质、乘除法"), lesson("p-ratio", "比和比例", "数与运算", .primary, "比的意义、比例尺与正反比例启蒙"), lesson("p-percent", "百分数超能力", "数与运算", .primary, "折扣、成数、税率和利率"), lesson("p-integer", "负数温度计", "数与运算", .primary, "用正负数描述生活中的相反量"),
        lesson("p-angle", "角度测量站", "图形几何", .primary, "角的分类、度量与画角"), lesson("p-area", "面积工程师", "图形几何", .primary, "长方形、正方形、组合图形面积"), lesson("p-volume", "体积实验室", "图形几何", .primary, "体积、容积和单位换算"), lesson("p-transform", "图形变变变", "图形几何", .primary, "平移、旋转、轴对称和位置"), lesson("p-solid", "立体观察员", "图形几何", .primary, "从不同方向观察立体图形"),
        lesson("p-stat", "统计小记者", "统计概率", .primary, "平均数、条形图、折线图与扇形图"), lesson("p-word", "应用题拆解术", "解决问题", .primary, "画线段图并选择合适数量关系"), lesson("p-speed", "速度任务局", "解决问题", .primary, "路程、速度、时间和相遇问题"),
        lesson("j-rational", "有理数航线", "数与式", .junior, "正负数、数轴、绝对值和有理数运算"), lesson("j-power", "乘方能量", "数与式", .junior, "乘方、科学记数法和平方根"), lesson("j-algebra", "整式工厂", "数与式", .junior, "整式加减、乘法公式与因式分解"), lesson("j-fraction", "分式密码", "数与式", .junior, "分式化简、运算与方程"), lesson("j-equation2", "一元一次方程", "方程", .junior, "从数量关系建立并解方程"), lesson("j-system", "方程组侦探", "方程", .junior, "二元一次方程组与实际问题"), lesson("j-inequality", "不等式边界", "方程", .junior, "一元一次不等式和数轴表示"),
        lesson("j-coordinate", "坐标定位", "函数", .junior, "平面直角坐标系与点的位置"), lesson("j-linear", "一次函数", "函数", .junior, "图像、性质与实际应用"), lesson("j-quadratic", "二次函数预览", "函数", .junior, "用图像观察开口、顶点和变化"), lesson("j-triangle", "三角形实验场", "图形几何", .junior, "三角形性质、全等与证明"), lesson("j-quadrilateral", "四边形研究所", "图形几何", .junior, "平行四边形、矩形、菱形、正方形"), lesson("j-circle", "圆的秘密", "图形几何", .junior, "圆、弧、扇形和圆周角"), lesson("j-similarity", "相似放大镜", "图形几何", .junior, "相似三角形与比例线段"), lesson("j-pythagoras", "勾股探险", "图形几何", .junior, "直角三角形边的关系"), lesson("j-data", "数据分析站", "统计概率", .junior, "平均数、中位数、众数与方差直觉"), lesson("j-counting", "概率与计数", "统计概率", .junior, "树状图、列表法和简单概率"),
        lesson("p-unit", "单位换算站", "量与计量", .primary, "长度、面积、体积、质量、时间单位换算"), lesson("p-law", "运算定律", "数与运算", .primary, "交换律、结合律、分配律和简便计算"), lesson("p-divisibility", "倍数与因数", "数与运算", .primary, "因数、倍数、质数、合数与最大公因数"), lesson("p-multiple", "公倍数集市", "数与运算", .primary, "最小公倍数与分数通分"), lesson("p-equation", "小小方程师", "代数启蒙", .primary, "用字母表示数并解简单方程"), lesson("p-average", "平均数实验", "统计概率", .primary, "平均数的意义与实际比较"), lesson("p-chart", "统计图工坊", "统计概率", .primary, "选择图表、读图和分析数据"), lesson("p-perimeter", "周长设计师", "图形几何", .primary, "长方形、正方形和组合图形周长"), lesson("p-surface", "表面积包装厂", "图形几何", .primary, "正方体、长方体表面积"), lesson("p-location", "位置导航", "图形几何", .primary, "用数对确定位置"),
        lesson("j-root", "实数根号", "数与式", .junior, "平方根、立方根与实数大小比较"), lesson("j-factor", "因式分解", "数与式", .junior, "提公因式、公式法和十字相乘"), lesson("j-radical", "二次根式", "数与式", .junior, "二次根式化简与运算"), lesson("j-quadratic-eq", "一元二次方程", "方程", .junior, "配方法、公式法与根的判别"), lesson("j-sequence", "数列找规律", "函数", .junior, "用递推和通项描述数列"), lesson("j-proof", "几何证明课", "图形几何", .junior, "命题、定理、辅助线与证明书写"), lesson("j-figure", "视图与投影", "图形几何", .junior, "三视图、展开图与投影"), lesson("j-trig", "锐角三角比", "图形几何", .junior, "正弦、余弦、正切的直观应用"), lesson("j-locus", "轨迹与作图", "图形几何", .junior, "尺规作图和点的轨迹"), lesson("j-sampling", "抽样调查", "统计概率", .junior, "总体、样本与抽样方法"), lesson("j-frequency", "频率分布", "统计概率", .junior, "频数、频率与分布图"),
        lesson("p-count", "数一数与比多少", "一年级基础", .primary, "10以内、20以内数数和比较大小"), lesson("p-add-sub", "加减法起步", "一年级基础", .primary, "20以内进位加法和退位减法"), lesson("p-shape", "认识图形", "一年级基础", .primary, "长方形、正方形、三角形和圆"), lesson("p-money", "认识人民币", "一年级基础", .primary, "元角分换算与简单购物"), lesson("p-table", "表内乘法", "二年级基础", .primary, "乘法意义、口诀和表内除法"), lesson("p-remainder", "有余数的除法", "二年级基础", .primary, "平均分、余数和简单应用题"), lesson("p-length", "长度单位", "二年级基础", .primary, "厘米、米、分米、毫米和测量"), lesson("p-multidigit", "多位数乘除法", "三年级基础", .primary, "两三位数乘一位数和除法估算"), lesson("p-fraction1", "分数初识", "三年级基础", .primary, "认识几分之一、同分母分数比较"), lesson("p-perimeter1", "周长入门", "三年级基础", .primary, "图形周长和长方形周长"), lesson("p-decimal1", "小数初识", "三年级基础", .primary, "小数读写、大小比较和加减"), lesson("p-multifraction", "分数运算", "四年级基础", .primary, "同分母分数加减和简单应用"), lesson("p-angle1", "角和线", "四年级基础", .primary, "直线、射线、线段、平行与垂直"), lesson("p-multi", "大数乘法", "四年级基础", .primary, "三位数乘两位数和除数是两位数"), lesson("p-five-fraction", "分数通关", "五年级基础", .primary, "分数乘法、除法和混合运算"), lesson("p-volume1", "长方体和正方体", "五年级基础", .primary, "棱长、表面积、体积和容积"), lesson("p-six-ratio", "比例应用", "六年级基础", .primary, "比例尺、图形放大缩小和正反比例"), lesson("p-six-circle", "圆形世界", "六年级基础", .primary, "圆周长、面积和扇形认识"), lesson("p-six-stat", "扇形统计图", "六年级基础", .primary, "百分数、扇形统计图和生活应用"),
        lesson("j-seventh-algebra", "代数式入门", "七年级基础", .junior, "用字母表示数、代数式求值和合并同类项"), lesson("j-seventh-lines", "相交线与平行线", "七年级基础", .junior, "对顶角、同位角、内错角和判定"), lesson("j-eighth-factor", "因式分解进阶", "八年级基础", .junior, "提公因式与平方差、完全平方公式"), lesson("j-eighth-data", "数据的波动", "八年级基础", .junior, "极差、方差与数据稳定性"), lesson("j-eighth-rotation", "图形的旋转", "八年级基础", .junior, "中心对称、旋转作图和性质"), lesson("j-ninth-circle", "圆与位置关系", "九年级基础", .junior, "点线圆位置关系、切线与弧长"), lesson("j-ninth-projection", "投影与视图", "九年级基础", .junior, "平行投影、中心投影和三视图"), lesson("j-ninth-practical", "数学建模任务", "九年级基础", .junior, "用方程、函数和统计解决综合问题")
    ]
    static var lessons: [Lesson] { (baseLessons + extendedLessons).map { lesson in
        guard let questions = questionBank[lesson.id], !questions.isEmpty else { return lesson }
        return Lesson(id: lesson.id, title: lesson.title, ability: lesson.ability, subject: lesson.subject, stage: lesson.stage, minutes: lesson.minutes, summary: lesson.summary, questions: questions)
    } }
    private static let questionBank: [String: [Question]] = [
        "p-four": [q("p-four-1", "125 + 376 = ?", ["401", "501", "601"], "501", "先算个位，再算十位和百位。"), q("p-four-2", "900 - 458 = ?", ["442", "452", "462"], "442", "注意退位：900-400-58=442。"), q("p-four-3", "25 × 16 最简便的算法是？", ["25×8×2", "25+16", "25×10+6"], "25×8×2", "先把 16 拆成 8×2。")],
        "p-decimal": [q("p-decimal-1", "3.6 + 2.45 = ?", ["5.05", "6.05", "6.5"], "6.05", "小数点对齐后再相加。"), q("p-decimal-2", "4.8 ÷ 10 = ?", ["48", "0.48", "0.048"], "0.48", "除以 10，小数点向左移动一位。")],
        "p-percent": [q("p-percent-1", "一件 80 元商品打九折，现价多少？", ["72元", "70元", "78元"], "72元", "80×90%=72。"), q("p-percent-2", "25 是 200 的百分之几？", ["8%", "12.5%", "25%"], "12.5%", "25÷200=12.5%。")],
        "p-area": [q("p-area-1", "长 8 厘米、宽 5 厘米的长方形面积？", ["13平方厘米", "26平方厘米", "40平方厘米"], "40平方厘米", "面积=长×宽。"), q("p-area-2", "边长 6 米的正方形周长？", ["12米", "24米", "36米"], "24米", "周长=边长×4。")],
        "p-speed": [q("p-speed-1", "小车每小时 60 千米，3 小时行驶多少？", ["20千米", "180千米", "360千米"], "180千米", "路程=速度×时间。"), q("p-speed-2", "路程 240 千米用时 4 小时，速度？", ["60千米/时", "960千米/时", "236千米/时"], "60千米/时", "速度=路程÷时间。")],
        "j-rational": [q("j-rational-1", "-3+8 = ?", ["-11", "5", "11"], "5", "异号相加，取绝对值较大的符号。"), q("j-rational-2", "|-7| = ?", ["-7", "0", "7"], "7", "绝对值表示到原点的距离。")],
        "j-equation2": [q("j-equation2-1", "解方程 2x+3=11", ["x=3", "x=4", "x=7"], "x=4", "先两边减 3，再除以 2。"), q("j-equation2-2", "若 5x=35，x=?", ["5", "7", "30"], "7", "两边同时除以 5。")],
        "j-system": [q("j-system-1", "x+y=10，x-y=2，则 x=?", ["4", "6", "8"], "6", "两式相加得 2x=12。"), q("j-system-2", "二元一次方程组常用方法？", ["代入或加减", "只试数字", "只画图"], "代入或加减", "根据系数关系选择消元方法。")],
        "j-linear": [q("j-linear-1", "一次函数 y=2x+1 的斜率是？", ["1", "2", "3"], "2", "x 的系数就是斜率。"), q("j-linear-2", "y=3x-2 中 x=0 时 y=?", ["-2", "0", "2"], "-2", "代入 x=0。")],
        "j-pythagoras": [q("j-pythagoras-1", "直角边 3、4 的直角三角形斜边？", ["5", "6", "7"], "5", "3²+4²=5²。"), q("j-pythagoras-2", "勾股定理适用于？", ["任意三角形", "直角三角形", "等边三角形"], "直角三角形", "它描述直角三角形三边关系。")],
        "j-data": [q("j-data-1", "数据 2、4、6 的平均数？", ["3", "4", "6"], "4", "总和 12 除以 3。"), q("j-data-2", "一组数据中出现次数最多的数叫？", ["平均数", "中位数", "众数"], "众数", "众数是频数最多的值。")],
        "p-fraction": [q("p-fraction-1", "1/2 和 1/3 哪个大？", ["1/2", "1/3", "一样大"], "1/2", "分子相同为 1 时，分母越小分数越大。"), q("p-fraction-2", "2/5+1/5=?", ["3/5", "3/10", "2/10"], "3/5", "同分母分数分母不变，分子相加。")],
        "p-ratio": [q("p-ratio-1", "2:3 的前项是？", ["2", "3", "5"], "2", "比号前的数叫前项。"), q("p-ratio-2", "10:15 化简为？", ["2:3", "3:2", "10:5"], "2:3", "前后项同时除以 5。")],
        "p-volume": [q("p-volume-1", "长 3、宽 2、高 4 的长方体体积？", ["9", "18", "24"], "24", "体积=长×宽×高。"), q("p-volume-2", "1立方分米等于多少立方厘米？", ["10", "100", "1000"], "1000", "体积单位进率是 1000。")],
        "p-stat": [q("p-stat-1", "条形统计图最适合表示？", ["数量多少", "变化趋势", "部分占比"], "数量多少", "条形图便于比较数量。"), q("p-stat-2", "3、5、7 的平均数？", ["4", "5", "6"], "5", "总和 15 除以 3。")],
        "j-algebra": [q("j-algebra-1", "3a+2a=?", ["5a", "6a", "5a²"], "5a", "合并同类项。"), q("j-algebra-2", "(x+2)(x+3) 展开？", ["x²+5x+6", "x²+6", "x²+5x"], "x²+5x+6", "逐项相乘再合并。")],
        "j-factor": [q("j-factor-1", "x²-9 的因式分解？", ["(x-3)(x+3)", "(x-9)(x+1)", "x(x-9)"], "(x-3)(x+3)", "使用平方差公式。"), q("j-factor-2", "6x+9 的公因式？", ["2", "3", "6x"], "3", "各项都能被 3 整除。")],
        "j-inequality": [q("j-inequality-1", "解 2x<6，x 的范围？", ["x<3", "x>3", "x=3"], "x<3", "两边同除以正数 2。"), q("j-inequality-2", "不等式解集常用什么表示？", ["数轴", "圆规", "量角器"], "数轴", "数轴能直观表示范围。")],
        "j-circle": [q("j-circle-1", "半径 3 的圆直径？", ["3", "6", "9"], "6", "直径是半径的 2 倍。"), q("j-circle-2", "圆周率通常取？", ["2.14", "3.14", "4.13"], "3.14", "圆周率约为 3.14。")],
        "j-quadratic-eq": [q("j-quadratic-eq-1", "x²=9 的解？", ["x=3", "x=±3", "x=9"], "x=±3", "平方为 9 的数有 3 和 -3。"), q("j-quadratic-eq-2", "一元二次方程最高次数是？", ["1", "2", "3"], "2", "未知数最高次数为 2。")],
        "j-counting": [q("j-counting-1", "抛一枚硬币正面朝上的概率？", ["0", "1/2", "1"], "1/2", "正反两种等可能结果。"), q("j-counting-2", "概率的取值范围？", ["0到1", "1到2", "任意数"], "0到1", "概率不小于 0 且不大于 1。")]
        ,"p-place": [q("p-place-1", "数字 5 在 35200 中表示？", ["5个百", "5个千", "5个万"], "5个千", "5 位于千位。"), q("p-place-2", "34900 约等于几万？", ["3万", "4万", "5万"], "3万", "千位小于 5，舍去尾数。")],
        "p-divisibility": [q("p-divisibility-1", "12 的因数有？", ["5", "3", "7"], "3", "3 能整除 12。"), q("p-divisibility-2", "最小的质数是？", ["0", "1", "2"], "2", "2 只有 1 和它本身两个因数。")],
        "p-equation": [q("p-equation-1", "x+8=20，x=?", ["12", "28", "160"], "12", "两边同时减 8。"), q("p-equation-2", "用字母表示正方形周长？", ["a+4", "4a", "a²"], "4a", "正方形周长是边长的 4 倍。")],
        "p-angle": [q("p-angle-1", "直角是多少度？", ["45°", "90°", "180°"], "90°", "直角等于 90 度。"), q("p-angle-2", "平角是多少度？", ["90°", "180°", "360°"], "180°", "平角是一条直线。")],
        "p-perimeter": [q("p-perimeter-1", "长 7 宽 3 的长方形周长？", ["10", "20", "21"], "20", "周长=(长+宽)×2。"), q("p-perimeter-2", "正方形周长 24，边长？", ["4", "6", "8"], "6", "边长=周长÷4。")],
        "j-power": [q("j-power-1", "2³ 等于？", ["6", "8", "9"], "8", "2×2×2=8。"), q("j-power-2", "√49 等于？", ["6", "7", "8"], "7", "7²=49。")],
        "j-coordinate": [q("j-coordinate-1", "点(2,3) 的横坐标？", ["2", "3", "5"], "2", "括号第一个数是横坐标。"), q("j-coordinate-2", "原点坐标？", ["(1,1)", "(0,0)", "(0,1)"], "(0,0)", "两条坐标轴交点是原点。")],
        "j-triangle": [q("j-triangle-1", "三角形内角和？", ["90°", "180°", "360°"], "180°", "任意三角形内角和为 180 度。"), q("j-triangle-2", "两边及其夹角对应相等可判定？", ["全等", "相似", "平行"], "全等", "这是边角边判定。")],
        "j-quadrilateral": [q("j-quadrilateral-1", "平行四边形对角线？", ["互相平分", "一定相等", "一定垂直"], "互相平分", "平行四边形对角线互相平分。"), q("j-quadrilateral-2", "矩形的四个角都是？", ["锐角", "直角", "钝角"], "直角", "矩形四角均为 90 度。")],
        "j-similarity": [q("j-similarity-1", "相似图形对应角？", ["相等", "互补", "无关"], "相等", "相似图形对应角相等。"), q("j-similarity-2", "相似三角形对应边比？", ["相等", "相反", "随意"], "相等", "对应边成比例。")]
        ,"p-money": [q("p-money-1", "3元5角等于多少角？", ["8角", "35角", "305角"], "35角", "1元=10角。"), q("p-money-2", "用 10 元买 6 元 5 角的物品，应找回？", ["3元5角", "4元5角", "16元5角"], "3元5角", "10元-6元5角=3元5角。")],
        "p-table": [q("p-table-1", "7×8=?", ["54", "56", "64"], "56", "七八五十六。"), q("p-table-2", "48÷6=?", ["6", "8", "9"], "8", "六八四十八。")],
        "p-multidigit": [q("p-multidigit-1", "24×3=?", ["62", "72", "82"], "72", "20×3+4×3=72。"), q("p-multidigit-2", "96÷3=?", ["32", "33", "36"], "32", "90÷3=30，6÷3=2。")],
        "p-decimal1": [q("p-decimal1-1", "0.5 表示？", ["5个一", "5个十分之一", "5个百分之一"], "5个十分之一", "小数点后一位是十分位。"), q("p-decimal1-2", "1.2+0.8=?", ["1.10", "2", "2.8"], "2", "十分位相加满十进一。")],
        "j-root": [q("j-root-1", "√16=?", ["2", "4", "8"], "4", "4²=16。"), q("j-root-2", "∛27=?", ["2", "3", "9"], "3", "3³=27。")],
        "j-radical": [q("j-radical-1", "√4+√9=?", ["5", "√13", "13"], "5", "分别求平方根再相加。"), q("j-radical-2", "√(a²) 在 a≥0 时等于？", ["a", "-a", "a²"], "a", "非负条件下主平方根为 a。")],
        "j-trig": [q("j-trig-1", "sin30°=?", ["1/2", "√2/2", "1"], "1/2", "特殊角三角函数值。"), q("j-trig-2", "直角三角形中 sinA 等于？", ["对边/斜边", "邻边/斜边", "对边/邻边"], "对边/斜边", "正弦定义为对边比斜边。")],
        "j-sampling": [q("j-sampling-1", "从全校学生中抽取 100 人调查视力，100人是？", ["总体", "样本", "个体"], "样本", "被抽取的一部分叫样本。"), q("j-sampling-2", "调查全校学生身高，研究对象总体是？", ["100人", "全校学生", "一个班"], "全校学生", "总体是研究对象的全体。")],
        "j-frequency": [q("j-frequency-1", "频率=频数÷？", ["总数", "平均数", "最大值"], "总数", "频率反映部分占总体的比例。"), q("j-frequency-2", "各组频率之和？", ["0", "1", "不确定"], "1", "所有组覆盖总体，频率和为 1。")]
        ,"p-six-circle": [q("p-six-circle-1", "半径 2 的圆周长约为？", ["6.28", "12.56", "25.12"], "12.56", "圆周长=2πr。"), q("p-six-circle-2", "圆的面积与什么有关？", ["半径平方", "直径相加", "周长减半"], "半径平方", "圆面积=πr²。")],
        "p-six-ratio": [q("p-six-ratio-1", "图上 1 厘米表示实际 5 米，比例尺？", ["1:5", "5:1", "1:500"], "1:500", "统一单位后 1厘米:500厘米。"), q("p-six-ratio-2", "正比例关系中比值？", ["不变", "变大", "变小"], "不变", "正比例的比值保持不变。")],
        "p-surface": [q("p-surface-1", "正方体棱长 2，表面积？", ["8", "24", "48"], "24", "6×2×2=24。"), q("p-surface-2", "长方体表面积包括几个面？", ["4个", "6个", "8个"], "6个", "长方体有 6 个面。")],
        "j-quadratic": [q("j-quadratic-1", "二次函数图像通常是？", ["直线", "抛物线", "圆"], "抛物线", "二次函数图像是抛物线。"), q("j-quadratic-2", "y=x² 的图像开口方向？", ["向上", "向下", "水平"], "向上", "二次项系数为正，开口向上。")],
        "j-figure": [q("j-figure-1", "从正面、左面、上面观察立体图形得到？", ["三视图", "统计图", "流程图"], "三视图", "三视图表达立体图形形状。"), q("j-figure-2", "正方体展开图有几个正方形？", ["4个", "6个", "8个"], "6个", "正方体有 6 个面。")],
        "j-locus": [q("j-locus-1", "到定点距离相等的点的轨迹是？", ["圆", "直线", "三角形"], "圆", "以定点为圆心、定长为半径形成圆。"), q("j-locus-2", "作线段垂直平分线常用工具？", ["直尺和圆规", "量筒", "天平"], "直尺和圆规", "垂直平分线可用尺规作图。")],
        "j-ninth-practical": [q("j-ninth-practical-1", "解决实际问题的第一步通常是？", ["审清题意建模", "直接猜答案", "只画图"], "审清题意建模", "先明确变量和数量关系。"), q("j-ninth-practical-2", "用统计图研究数据前要先做什么？", ["收集整理数据", "随意删数据", "只看最大值"], "收集整理数据", "可靠数据是分析的基础。")]
    ]
    private static func q(_ id: String, _ prompt: String, _ options: [String], _ answer: String, _ explanation: String) -> Question { Question(id: id, prompt: prompt, kind: .choice, choices: options.map { QuestionChoice(id: $0, text: $0) }, answer: answer, explanation: explanation) }
    private static func lesson(_ id: String, _ title: String, _ ability: String, _ stage: Stage, _ summary: String) -> Lesson {
        let questions = [
            Question(id: "\(id)-concept", prompt: "关于“\(title)”的第一步是什么？", kind: .choice, choices: [QuestionChoice(id: "a", text: "先说清定义"), QuestionChoice(id: "b", text: "直接跳过")], answer: "a", explanation: "先理解概念，再开始计算。"),
            Question(id: "\(id)-apply", prompt: "学习“\(title)”后，怎样确认掌握？", kind: .choice, choices: [QuestionChoice(id: "a", text: "完成一道基础题"), QuestionChoice(id: "b", text: "只看答案")], answer: "a", explanation: "基础题可以验证方法是否掌握。"),
            Question(id: "\(id)-review", prompt: "遇到“\(title)”时，更好的习惯是？", kind: .choice, choices: [QuestionChoice(id: "a", text: "写出步骤并检查"), QuestionChoice(id: "b", text: "凭感觉作答")], answer: "a", explanation: "写步骤能帮助发现思路中的错误。")
        ]
        return Lesson(id: id, title: title, ability: ability, subject: .math, stage: stage, minutes: 8, summary: summary, questions: questions)
    }
    static func lessons(for stage: Stage) -> [Lesson] { lessons.filter { $0.stage == stage } }
}
