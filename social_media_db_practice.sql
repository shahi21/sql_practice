--TABLE CREATION
CREATE table users(
user_id serial primary key,
username varchar(50) unique not null,
email varchar(50) unique not null,
created_at timestamp default current_timestamp
);

create table posts(
post_id serial primary key,
user_id int references users(user_id) on delete cascade,
content text not null,
created_at timestamp default current_timestamp
);

create table followers(
follower_id int references users(user_id) on delete cascade,
following_id int references users(user_id) on delete cascade,
followed_at timestamp default current_timestamp,
primary key(follower_id,following_id),
check(follower_id <> following_id)
);

-- TABLE FOR TRIGGER
create table activity_log(
log_id serial primary key,
user_id int references users(user_id) on delete cascade,
action text not null,
timestamp timestamp default current_timestamp
);

-- INSERTING DATA INTO TABLES
select * from users;
insert into users(username,email) values
('alice', 'alice@gmail.com'),
('bob', 'bob@gmail.com'),
('charlie', 'charlie@gmail.com'),
('david', 'david@gmail.com'),
('eve', 'eve@gmail.com'),
('frank', 'frank@gmail.com'),
('grace', 'grace@gmail.com'),
('henry', 'henry@gmail.com'),
('isabel', 'isabel@gmail.com'),
('jack', 'jack@gmail.com');


select * from posts;
insert into posts(user_id,content) values
(1, 'Hello, world!'),
(2, 'I love PostgreSQL!'),
(3, 'What a beautiful day!'),
(4, 'Coding is life.'),
(5, 'Just watched a great movie.'),
(6, 'Reading a fantastic book.'),
(7, 'Exploring new places.'),
(8, 'Trying out a new recipe.'),
(9, 'Starting my new blog.'),
(10, 'Fitness is my passion.');

select * from followers;
insert into followers(follower_id,following_id) values
(1, 2), 
(1, 3), 
(2, 3), 
(2, 4), 
(3, 1),
(3, 5),
(4, 6),
(5, 7), 
(6, 8), 
(7, 9),
(8, 10), 
(9, 1),
(10, 2),
(5, 4), 
(3, 7);

-- QUERIES
--get all posts with user details
select u.username,p.content
from posts p
join users u on p.user_id=u.user_id;

--find all followers of a user
select u.username as follower, follower_id
from followers f
join users u on f.follower_id=u.user_id
where f.following_id=3;

--find users followed by a specific user
select u.username as following
from followers f
join users u on f.following_id=u.user_id
where f.follower_id=1;

--find mutual followers(users who follow each other)
select u1.username as user1, u2.username as user2
from followers f1
join followers f2 on f1.follower_id= f2.following_id and f1.following_id=f2.following_id
join users u1 on f1.follower_id=u1.user_id
join users u2 on f1.following_id=u2.user_id;


--find users who follow at least 3 people
select u.username, count(f.following_id) as following_count
from users u
join followers f on u.user_id=follower_id
group by u.username
having count(f.following_id)>=3;

--find users with the most followers
select u.username, count(f.follower_id) as follower_count
from users u
join followers f on u.user_id=f.following_id
group by u.username
order by follower_count desc
limit 1;


-- CREATING TRIGGER

create or replace function log_post_activity()
returns trigger as $$
begin
	if tg_op='INSERT' then
	insert into activity_log(user_id,action) values
	(new.user_id,'created a new post');
	elseif tg_op='DELETE' then
	insert into activity_log(user_id,action) values
	(old.user_id,'Deleted a post');
	end if;
	return null;
end;
$$ language plpgsql;

create trigger post_activity_trigger
after insert or delete on posts
for each row
execute function log_post_activity();


-- TESTING TRIGGER

--inserting new post(trigger for insert)

insert into posts (post_id,user_id,content) values
(11,1,'Hello,this is my post to test trigger for insert');

select * from activity_log;
select * from posts;

delete from posts where post_id=11;
select * from activity_log;



-- query

--find recent activity logs
select u.username, a.action,a.timestamp
from activity_log a
join users u on a.user_id=u.user_id;




