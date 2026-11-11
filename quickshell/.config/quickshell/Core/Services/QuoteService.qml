import QtQuick
pragma Singleton

QtObject {
    property var categories: ["All"]
    property string currentCategory: SettingsService.quoteCategory
    property var quotes: [{
        "text": "Хватит рассуждать о том, каким должен быть хороший человек. Пора им стать.",
        "author": "Марк Аврелий",
        "category": "Philosophy"
    }, {
        "text": "Мы чаще страдаем в воображении, чем в действительности.",
        "author": "Сенека",
        "category": "Philosophy"
    }, {
        "text": "Я знаю, что ничего не знаю.",
        "author": "Сократ",
        "category": "Philosophy"
    }, {
        "text": "Жизнь — это то, что происходит, пока ты строишь другие планы.",
        "author": "Джон Леннон",
        "category": "Life"
    }, {
        "text": "Жизнь не коротка — мы сами делаем её такой, растрачивая время.",
        "author": "Сенека",
        "category": "Philosophy"
    }, {
        "text": "Ты властен над своим умом, а не над внешними событиями. Пойми это — и обретёшь силу.",
        "author": "Марк Аврелий",
        "category": "Philosophy"
    }, {
        "text": "Болтать легко. Покажи код.",
        "author": "Линус Торвальдс",
        "category": "Programming"
    }, {
        "text": "Сначала реши задачу. Потом пиши код.",
        "author": "Джон Джонсон",
        "category": "Programming"
    }, {
        "text": "Сделай, чтобы работало, потом — правильно, потом — быстро.",
        "author": "Кент Бек",
        "category": "Programming"
    }, {
        "text": "Программы пишут для того, чтобы их читали люди, и лишь заодно — чтобы их исполняли машины.",
        "author": "Гарольд Абельсон",
        "category": "Programming"
    }, {
        "text": "Код как шутка: если его приходится объяснять, он плохой.",
        "author": "Кори Хаус",
        "category": "Programming"
    }, {
        "text": "Простота — душа эффективности.",
        "author": "Остин Фриман",
        "category": "Programming"
    }, {
        "text": "В программировании есть две сложные вещи: инвалидация кеша и придумывание имён.",
        "author": "Фил Карлтон",
        "category": "Programming"
    }, {
        "text": "Чтобы понять рекурсию, нужно сначала понять рекурсию.",
        "author": "Неизвестный автор",
        "category": "Programming"
    }, {
        "text": "Это не баг, это недокументированная возможность.",
        "author": "Неизвестный автор",
        "category": "Humor"
    }, {
        "text": "Хорошо с булевыми значениями: даже если ошибёшься, то всего на один бит.",
        "author": "Неизвестный автор",
        "category": "Humor"
    }, {
        "text": "Сложность — твой враг. Усложнить может любой дурак.",
        "author": "Тони Хоар",
        "category": "Programming"
    }, {
        "text": "Прежде чем стать переиспользуемой, программа должна стать пригодной к использованию.",
        "author": "Ральф Джонсон",
        "category": "Programming"
    }, {
        "text": "Преждевременная оптимизация — корень всех зол.",
        "author": "Дональд Кнут",
        "category": "Programming"
    }, {
        "text": "Задача хорошей программы — сделать невидимое видимым.",
        "author": "Стив Макконнелл",
        "category": "Programming"
    }, {
        "text": "Любой дурак напишет код, понятный компьютеру. Хорошие программисты пишут код, понятный людям.",
        "author": "Мартин Фаулер",
        "category": "Programming"
    }, {
        "text": "Правду можно найти только в одном месте — в коде.",
        "author": "Роберт Мартин",
        "category": "Programming"
    }, {
        "text": "Счастье — идеал не разума, а воображения.",
        "author": "Иммануил Кант",
        "category": "Philosophy"
    }, {
        "text": "Мы то, что мы постоянно делаем. Совершенство — не поступок, а привычка.",
        "author": "Аристотель",
        "category": "Philosophy"
    }, {
        "text": "Однажды компьютер обыграл меня в шахматы, но в кикбоксинге ему со мной не тягаться.",
        "author": "Эмо Филипс",
        "category": "Humor"
    }, {
        "text": "Молодость счастлива, потому что умеет видеть прекрасное. Кто сохранил эту способность, никогда не состарится.",
        "author": "Франц Кафка",
        "category": "Life"
    }, {
        "text": "Страстно веря в то, чего ещё нет, мы это создаём.",
        "author": "Франц Кафка",
        "category": "Philosophy"
    }, {
        "text": "У кого есть «зачем» жить, тот выдержит почти любое «как».",
        "author": "Фридрих Ницше",
        "category": "Philosophy"
    }, {
        "text": "Тех, кто танцевал, считали безумцами те, кто не слышал музыки.",
        "author": "Фридрих Ницше",
        "category": "Philosophy"
    }, {
        "text": "Умер мой психолог по утратам. Он был так хорош, что мне даже не грустно.",
        "author": "Гэри Делейни",
        "category": "Humor"
    }, {
        "text": "Даже ни на что не годные люди могут вызвать улыбку — например, когда толкаешь их с лестницы.",
        "author": "Неизвестный автор",
        "category": "Humor"
    }, {
        "text": "Никогда не забуду последние слова дедушки: «Ты там лестницу держишь?»",
        "author": "Неизвестный автор",
        "category": "Humor"
    }, {
        "text": "Играли мы с другом в шахматы, и он сказал: «Давай сделаем игру интереснее». И мы бросили шахматы.",
        "author": "Мэтт Киршен",
        "category": "Humor"
    }]
    property var currentQuote

    function getCategories() {
        for (let i = 0; i < quotes.length; i++) {
            if (!categories.includes(quotes[i].category))
                categories.push(quotes[i].category);

        }
    }

    function generateRandomQuote() {
        let arr = [];
        for (let i = 0; i < quotes.length; i++) {
            if (currentCategory === "All" || quotes[i].category === currentCategory)
                arr.push(quotes[i]);

        }
        if (arr.length === 0)
            return ;

        if (arr.length === 1) {
            currentQuote = arr[0];
            return ;
        }
        let randomIndex = Math.floor(Math.random() * arr.length);
        let selectedQuote = arr[randomIndex];
        while (currentQuote && selectedQuote.text === currentQuote.text) {
            randomIndex = Math.floor(Math.random() * arr.length);
            selectedQuote = arr[randomIndex];
        }
        currentQuote = selectedQuote;
    }

    Component.onCompleted: {
        getCategories();
        generateRandomQuote();
    }
    onCurrentCategoryChanged: {
        generateRandomQuote();
    }
}
