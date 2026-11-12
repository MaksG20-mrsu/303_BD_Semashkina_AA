#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u1.name AS user1, u2.name AS user2, m.title FROM ratings AS r1 JOIN ratings AS r2 ON r1.movie_id = r2.movie_id JOIN users AS u1 ON r1.user_id = u1.id JOIN users AS u2 ON r2.user_id = u2.id JOIN movies AS m ON r1.movie_id = m.id WHERE r1.user_id < r2.user_id GROUP BY u1.name, u2.name, m.title ORDER BY m.title, u1.name, u2.name LIMIT 100"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS review_date FROM ratings AS r JOIN users AS u ON r.user_id = u.id JOIN movies AS m ON r.movie_id = m.id ORDER BY r.timestamp DESC LIMIT 10"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке Рекомендуем для фильмов должно быть написано Да или Нет."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies AS m JOIN ratings AS r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year), min_max AS (SELECT MIN(avg_rating) AS min_rating, MAX(avg_rating) AS max_rating FROM avg_ratings) SELECT ar.year, ar.title, ar.avg_rating, CASE WHEN ar.avg_rating = mm.max_rating THEN 'Да' ELSE 'Нет' END AS Рекомендуем FROM avg_ratings ar CROSS JOIN min_max AS mm WHERE ar.avg_rating = mm.min_rating OR ar.avg_rating = mm.max_rating ORDER BY ar.year, ar.title"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS количество_оценок, ROUND(AVG(r.rating), 2) AS средняя_оценка FROM ratings AS r JOIN users AS u ON r.user_id = u.id WHERE u.gender = 'female' AND strftime('%Y', date(r.timestamp, 'unixepoch')) BETWEEN '2010' AND '2012'"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (SELECT m.year, m.title, AVG(r.rating) AS avg_rating FROM movies AS m JOIN ratings AS r ON m.id = r.movie_id GROUP BY m.id, m.year, m.title), ranked AS (SELECT year, title, ROUND(avg_rating, 2) AS средняя_оценка, RANK() OVER (ORDER BY avg_rating DESC) AS место_в_рейтинге FROM avg_ratings) SELECT * FROM ranked ORDER BY year, title LIMIT 20"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате Фамилия Имя|Дата регистрации (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS результат FROM users ORDER BY register_date DESC LIMIT 10"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Должен получиться один столбец следующего вида: 1x1=1 ... 10x10=100"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE numbers(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM numbers WHERE n < 10), multiplication AS (SELECT n AS i, m AS j FROM numbers CROSS JOIN numbers) SELECT i || 'x' || j || '=' || (i * j) AS таблица_умножения FROM multiplication ORDER BY i, j"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres AS (SELECT id, substr(genres, 1, CASE WHEN instr(genres, '|') > 0 THEN instr(genres, '|') - 1 ELSE length(genres) END) AS genre, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END AS remaining FROM movies WHERE genres IS NOT NULL AND genres != '' UNION ALL SELECT id, substr(remaining, 1, CASE WHEN instr(remaining, '|') > 0 THEN instr(remaining, '|') - 1 ELSE length(remaining) END) AS genre, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, instr(remaining, '|') + 1) ELSE '' END FROM split_genres WHERE remaining != '') SELECT DISTINCT genre AS жанр FROM split_genres ORDER BY genre"
echo " "
