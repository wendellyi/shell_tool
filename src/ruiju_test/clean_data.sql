-- 切换数据库
USE IPS_3000;

-- 删除所有虚拟PBX帐号
DELETE FROM VirtualPbx WHERE `Domain` <> 0;

-- 删除所有虚拟PBX帐号上的理由组
DELETE FROM RouteGroupName WHERE `Domain` <> 0;

-- 删除所有虚拟PBX帐号上的路由项目
DELETE FROM RouteGroup WHERE `Domain` <> 0;

-- 删除所有虚拟PBX帐号上路由计划项目
DELETE FROM RoutePlan WHERE `Domain` <> 0;

-- 删除所有虚拟PBX帐号上的路由计划项目
DELETE FROM RoutePlanName WHERE `Domain` <> 0;

-- 删除所有用户类型为0的用户数据
DELETE FROM `User` WHERE `UserType` = 0;

-- 删除所有SIPT帐号
TRUNCATE TABLE SipTAccount;
