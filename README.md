## Отчет по заданию "RetailAnalytics":



## Проект "RetailAnalytics"

RetailAnalytics - это инструмент для анализа данных и оптимизации бизнес-процессов в розничных сетях. Он помогает компаниям понять своих клиентов, управлять ассортиментом, формировать персонализированные предложения и улучшать эффективность продаж.

Основные функции:

Сегментация клиентов
Анализ транзакций
Формирование персонализированных предложений
Управление инвентаризацией
Технологии:
RetailAnalytics использует современные технологии аналитики данных, такие как базы данных, языки программирования и инструменты визуализации.

## Part 1. Создание базы данных

part1.sql создает базу данных и таблицы согласно входным данным.
Включены процедуры для импорта и экспорта данных из/в файлы .csv и .tsv.
Добавлено по 5 записей в каждую таблицу.
Файлы .csv и .tsv для данных должны быть добавлены в GIT репозиторий.

## Part 2. Создание представлений

part2.sql создает представления, описанные в выходных данных.
Включены тестовые запросы.
Более подробная информация в папке materials.

## Part 3. Ролевая модель

part3.sql создает роли и назначает права:
Администратор: полные права на редактирование, просмотр и управление процессом.
Посетитель: право только на просмотр данных из всех таблиц.

## Part 4. Формирование персональных предложений, ориентированных на рост среднего чека

Функция определения предложений для увеличения среднего чека
Параметры функции:
Метод расчета среднего чека (1 - за период, 2 - за количество)
Первая и последняя даты периода (для метода 1)
Количество транзакций (для метода 2)
Коэффициент увеличения среднего чека
Максимальный индекс оттока
Максимальная доля транзакций со скидкой (в процентах)
Допустимая доля маржи (в процентах)
Определение условий предложения:
Выбор метода расчета среднего чека:

Пользователь может выбрать метод расчета: за определенный период времени или за определенное количество последних транзакций.
Определение среднего чека:

Для каждого клиента определяется текущее значение его среднего чека согласно выбранному методу.
Определение целевого значения среднего чека:

Рассчитанное значение среднего чека умножается на коэффициент, заданный пользователем.
Определение вознаграждения:
Определение группы для формирования вознаграждения:

Выбирается группа по критериям:
Максимальный индекс востребованности.
Индекс оттока не превышает заданное значение.
Доля транзакций со скидкой не превышает заданное значение.
Определение максимально допустимого размера скидки для вознаграждения:

Пользователь определяет долю маржи, которую можно использовать для предоставления скидки.
Определение величины скидки:

Сравнивается значение максимальной допустимой скидки с минимальной скидкой для клиента по группе.
Величина скидки устанавливается как максимум из этих значений, округленных с шагом в 5%.

## Part 5. Формирование персональных предложений, ориентированных на рост частоты визитов

Функция определения предложений для увеличения частоты визитов
Параметры функции:
Первая и последняя даты периода
Добавляемое число транзакций
Максимальный индекс оттока
Максимальная доля транзакций со скидкой (в процентах)
Допустимая доля маржи (в процентах)
Определение условий предложения:
Определение периода:

Пользователь задает период действия предложения, указывая первую и последнюю даты.
Определение текущей частоты посещений клиента:

Вычитается первая дата из последней в указанном периоде, затем результат делится на среднюю интенсивность транзакций клиента. Полученное значение сохраняется как базовая интенсивность транзакций клиента в указанный период.
Определение транзакции для начисления вознаграждения:

Система определяет номер транзакции в рамках заданного периода, на которую будет начислено вознаграждение.
Результат округляется согласно арифметическим правилам до целого, после чего к нему добавляется число транзакций, указанное пользователем.
Определение вознаграждения:
Определение группы для формирования вознаграждения:

Выбирается группа по критериям:
Максимальный индекс востребованности.
Индекс оттока не превышает заданное значение.
Доля транзакций со скидкой не превышает заданное значение.
Определение максимально допустимого размера скидки для вознаграждения:

Пользователь определяет долю маржи, которую можно использовать для предоставления скидки.
Определение величины скидки:

Сравнивается значение максимальной допустимой скидки с минимальной скидкой для клиента по группе.
Величина скидки устанавливается как максимум из этих значений, округленных вверх с шагом в 5%.

## Part 6. Формирование персональных предложений, ориентированных на кросс-продажи

Функция определения предложений для кросс-продаж, направленных на рост маржи
Параметры функции:
Количество групп
Максимальный индекс оттока
Максимальный индекс стабильности потребления
Максимальная доля SKU (в процентах)
Допустимая доля маржи (в процентах)
Определение условий предложения:
Выбор групп:

Для каждого клиента выбирается несколько групп с максимальным индексом востребованности, удовлетворяющих условиям оттока и стабильности потребления.
Определение SKU с максимальной маржой:

В каждой группе определяется SKU с максимальной маржой, вычисляемой как разница между розничной и закупочной ценой.
Определение доли SKU в группе:

Вычисляется доля транзакций, в которых присутствует анализируемое SKU, относительно общего числа транзакций в группе.
Определение вознаграждения:
Определение доли маржи для расчета скидки:

Пользователь задает долю маржи для предоставления вознаграждения.
Расчет скидки:

Вычисляется размер скидки на основе разницы между розничной и закупочной ценой, учитывая заданную долю маржи.
Если размер скидки удовлетворяет минимальному требуемому значению, то предложение формируется для клиента.
