# Реляционная алгебра и исчисление кортежей

> Ниже описаны два спопоба манипуляции реляционными данными - структурный и описательный

## Операторы реляционной алгебры

### Традиционные операторы

> Данные операторы эквивалентны соответствущим операторам теории множеств

| Оператор | Обозначение | 
| --- | --- |
| Объединение | `union` |  
| Пересечение | `intersect` |
| Разность | `minus` |
| Декартово произведение | `times` | 
 
---

### Специальные реляционные операторы

| Оператор | Обозначение | 
| --- | --- |
| Ограничение | `where` |  
| Проекция |  `project` |
| Соединение | `join` |
| Деление | `divide by` | 
| Переименование | `rename` |

**Пример №1.** Проекция

Для таблицы `T`:

| id | name | city |
| --- | --- | --- |
| 1 | nick | moscow |
| 2 | sam | new york |
| 3 | tay | moscow |
| 4 | ley | moscow |

Проекция `T[city]`:

| city |
| --- | 
| moscow | 
| new york | 

---

**Пример №2.** Деление

Для таблицы `T`:

| id_supplier | id_product |
| --- | --- |
| 1 | 1 |
| 1 | 2 |
| 1 | 3 | 
| 2 | 1 | 
| 2 | 2 | 
| 3 | 1 | 

Проекция `T[id_product]`:
| id_product |
| --- |
| 1 | 
| 2 |
| 3 | 

Результат деления `T divide by T[id_product]` есть поставщики, которые поставляют все детали:

| id_supplier |
| --- |
| 1 | 

---

### Зависимые операторы

> Некорые операторы РА выразимы через другие

Соединение по атрибуту `Y`:
```
A join B = ((A times (B rename Y as Y_1)) where Y = Y_1)[X, Y, Z]
```

Пересечение:
```
A intersect B = A minus (A minus B)
```

Деление:
```
A divide by B = A[X] minus ((A[X] times B) minus A)[X]
```

---

### Дополнительные операторы РА

* **Расширение `extend`** - получение отношения с новым атрибутом, полученным путем скалярного горизонтального вычисления 

**Пример №3.** Расширение

| Запрос | Синтаксис |
| --- | --- |
Добавить новый атрибут | `extend P add (Weigth * 454) as gmwt` |
Добавить копию атрибута `city` и вывести новую таблицу, но без столбца `city` | `(extend S add City as SCity){all but City}` |

---

* **Обобщение `summarize`** - вертикальный аналог расширения

**Пример №4.** Для каждого поставщика определить кол-во единиц поставляемого товара

```
summarize SP per PS {Pno} add sum(Qty) as totqty
```


## Исчисление кортежей

> Способ описания результирующего отношения на базе данных



## Примеры запросов

**Таблица поставщиков `S`**
| Sno | Sname | Status | City |
| --- | --- | --- | --- | 

---

**Таблица деталей `P`**
| Pno | Pname | Color | Weight | City |
| --- | --- | --- | --- | --- |

---

**Инфмормация о том, какие детали кем поставлюятся `SP`**
| Sno | Pno | Qty |
| --- | --- | --- |

---

1. Получить имена поставщиков, поставляющих деталь под номером 2.
    * Объединить таблицы `SP` и `S`, взять только строки, где `Pno=2` и выбрать из них уникальные значения атрибута `Sname`

    ```
    ((SP join S) where Pno=2)[Sname]
    ```
    
    * Взять из таблицы поставщиков такие имена, для которых в таблице связей существуют такие записи, где номер `Pno=2`
    ```
    SX.Sname where exists SPX (SPX.Sno=SX.Sno and SPX.Pno=2)
    ```

2. Получить имена поставщиков, поставляющих хотя бы одну красную деталь
    ```
    (((P where Color='red) join SP)[Sno] join S)[Sname]
    ```
    ```
    SX.Sname where exists SPX(
        SX.Sno=SPX.Sno and
        exists(PX.Pno=SPX.Pno and PX.color='red)
    )
    ```