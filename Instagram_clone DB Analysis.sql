show databases;
use ig_clone;
show tables;

-- How many times does the average user post?
with AVG_USER_POSTS as 
(select id as Photo_id, user_id, created_at, count(image_url) over(partition by user_id) as USER_POSTS from photos)

select *, Avg(USER_POSTS) over() from AVG_USER_POSTS;


-- Find the top 5 most used hashtags.
select id, image_url, user_id, count(PT.tag_id) from photos P
inner join photo_tags PT
ON PT.photo_id = P.id
group by photo_id order by count(PT.tag_id) desc limit 5;


-- Find users who have liked every single photo on the site.
with liked_photos as 
(select user_id, count(user_id) as liked_users_count from likes group by 1)

select user_id, liked_users_count from liked_photos
where liked_users_count = (select max(liked_users_count) as MAX_LIKES from liked_photos);


-- Retrieve a list of users along with their usernames and the rank of their account creation, 
-- ordered by the creation date in ascending order.
select *, rank() over(order by created_at) as USER_RANK from users;


-- List the comments made on photos with their comment texts, photo URLs, and usernames of users who posted the comments. 
-- Include the comment count for each photo
with CTE_Comments as 
(select C.user_id, U.username, C.photo_id, C.comment_text, P.image_url from comments C
Inner join photos P ON P.id = C.photo_id
inner join users U ON U.id = P.user_id)

select *, count(comment_text) over(partition by photo_id) as Comment_count from CTE_Comments;


-- For each tag, show the tag name and the number of photos associated with that tag. Rank the tags by the number of photos in descending order.
with CTE_TAG_RANK as 
(select T.id, T.tag_name, count(PT.photo_id) as photo_count from photo_tags PT
Inner join tags T ON PT.tag_id = T.id group by 1,2) 

select *, rank() over(order by photo_count desc) as Tag_Rank_By_Photos from CTE_TAG_RANK;


-- List the usernames of users who have posted photos along with the count of photos they have posted. 
-- Rank them by the number of photos in descending order.
with CTE_UserPosts_Rank as 
(select U.id, U.username, count(*) as Number_of_Posts from users U
inner join photos P
ON P.user_id = U.id
group by 1,2 
order by Number_of_Posts desc)
select id, username, Number_of_Posts, rank() over(order by Number_of_Posts desc) as Photo_Rank from CTE_UserPosts_Rank;


-- Display the username of each user along with the creation date of their first posted photo and the creation date of their next posted photo.
SELECT u.username AS Username,
    MIN(p1.created_at) AS First_Photo_Creation_Date,
    MIN(p2.created_at) AS Next_Photo_Creation_Date
FROM users u
LEFT JOIN photos p1 ON u.id = p1.user_id
LEFT JOIN photos p2 ON u.id = p2.user_id AND p2.created_at > p1.created_at
GROUP BY u.username;

-- For each comment, show the comment text, the username of the commenter, and the comment text of the previous comment made on the same photo.
SELECT u.username AS Commenter_Username,
	c1.comment_text AS Comment_Text, 
	c2.comment_text AS Previous_Comment_Text
FROM comments c1
LEFT JOIN comments c2 ON c1.photo_id = c2.photo_id AND c1.id > c2.id
left join users u ON u.id = c1.user_id;


-- Show the username of each user along with the number of photos they have posted and the number of photos posted by the user 
-- before them and after them, based on the creation date
WITH RankedPhotos AS (
    SELECT p.user_id, p.created_at,
        ROW_NUMBER() OVER (PARTITION BY p.user_id ORDER BY p.created_at) AS PhotoRank,
        COUNT(*) OVER (PARTITION BY p.user_id) AS TotalPhotos
    FROM photos p
),
UserPhotosWithRanks AS (
    SELECT u.username AS User_Name,
        r.user_id as user_id,
        r.PhotoRank,
        r.TotalPhotos
    FROM users u
    LEFT JOIN RankedPhotos r ON u.id = r.user_id
)
SELECT upwr.User_Name, upwr.TotalPhotos AS Number_of_Photos_Posted,
    LAG(upwr.TotalPhotos) OVER (ORDER BY upwr.PhotoRank) AS Photos_Before,
    LEAD(upwr.TotalPhotos) OVER (ORDER BY upwr.PhotoRank) AS Photos_After
FROM UserPhotosWithRanks upwr
ORDER BY upwr.PhotoRank;

