-- Проанализировать какие запросы могут выполняться наиболее часто в процессе работы приложения и добавить необходимые индексы.
use vk; 
SELECT * FROM friendship;

CREATE INDEX users_user_id_idx ON users(id);
CREATE INDEX profiles_user_id_idx ON profiles(user_id);
CREATE INDEX profiles_birthdate_idx ON profiles(birthdate);
CREATE INDEX messages_from_user_id_to_user_id_idx ON messages (from_user_id, to_user_id);
CREATE INDEX fr_friend_id_idx ON friendship(friend_id);
CREATE INDEX likes_target_idx ON likes (target_id);


-- Задание на оконные функции.
-- Провести аналитику в разрезе групп.
-- Построить запрос, который будет выводить следующие столбцы:
-- имя группы
-- среднее количество пользователей в группах
-- самый молодой пользователь в группе
-- самый пожилой пользователь в группе
-- количество пользователей в группе
-- всего пользователей в системе
-- отношение в процентах (количество пользователей в группе / всего пользователей в системе) * 100

 
 SHOW tables;
  SELECT count(id) FROM communities;
  SELECT * FROM communities_users;
  SELECT * FROM profiles;
  
  SELECT DISTINCT 
  communities.name,
  count(communities_users.user_id) OVER () / (SELECT count(id) FROM communities) as avg_member,
  count(communities_users.user_id)  OVER (PARTITION BY communities_users.community_id) AS caunt_member_group,
  count(communities_users.user_id)  OVER () AS total_user,
  count(communities_users.user_id)  OVER (PARTITION BY communities_users.community_id) / count(communities_users.user_id)  OVER () * 100 as '%',
  FIRST_VALUE(profiles.user_id) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS jung_user,
  last_value(profiles.user_id) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS old_user
	FROM communities
      JOIN communities_users
        ON communities.id = communities_users.community_id
        JOIN profiles
        ON profiles.user_id = communities_users.user_id;
    
-- c датами все равно не порядок, по логике все правильно но что- то все равно не так

  SELECT DISTINCT 
  communities.name,        
FIRST_VALUE(profiles.user_id) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS jung_user,
  last_value(profiles.user_id) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS old_user,
  FIRST_VALUE(profiles.birthdate) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS jung_user,
  last_value(profiles.birthdate) OVER (PARTITION BY profiles.birthdate order by profiles.birthdate) AS old_user 
	FROM communities
      JOIN communities_users
        ON communities.id = communities_users.community_id
        JOIN profiles
        ON profiles.user_id = communities_users.user_id;
        

-- Разобраться как построен и работает следующий запрос:
-- Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.
-- ВЫБЕРИТЕ users.id,

COUNT (DISTINCT messages.id) +
COUNT (DISTINCT likes.id) +
COUNT (DISTINCT media.id) AS 'деятельность'
LEFT JOIN 
ON users.id = messages.from_user_id
LEFT JOIN 
ON users.id = likes.user_id
LEFT JOIN СМИ
ON users.id = media.user_id
GROUP BY users.id
LIMIT 10;

-- Правильно-ли он построен?
-- Какие изменения, включая денормализацию, можно внести в структуру БД чтобы существенно повысить скорость работы этого запроса?
SELECT * FROM users;
SELECT * FROM messages;
SELECT * FROM likes;
SELECT * FROM media;


SELECT distinct
COUNT(messages.id) +
COUNT(likes.id) +
COUNT(media.id) AS activity
FROM users
LEFT JOIN 
messages
ON users.id = messages.from_user_id
LEFT JOIN 
likes
ON users.id = likes.user_id
LEFT JOIN 
media
ON users.id = media.user_id
GROUP BY users.id
LIMIT 10;

-- Вероятно можно проиндексировать столбцы, участвующие в запросе и , наверное можно создать временную таблицу или представление один раз, 
-- в которой можно записать столбцы, участвующие в этом запросе и потом обращаться к этой временой таблице.

