create database MindX_Lec_4


-- Tạo bảng CUSTOMER_GROUP
-- Summary: group by
-- Subquery
-- Số lần mua > 20 : Khách hàng thân thiết
-- 20 >= Số lần mua > 15: Khách hàng cấp 2
-- 15 >= Số lần mua > 8: Khách hàng cấp 1
--  8 >= Số lần mua > 3: Khách hàng tiềm năng
-- Số lần mua =<3  : Khách hàng mới 

select *, 
       case when NumberOfOrders <= 3 then N'Khách hàng mới'
            when NumberOfOrders <= 8 then N'Khách hàng tiềm năng'
            -- when NumberOfOrders <= 15 then N'Khách hàng cấp 1'
            -- when NumberOfOrders <= 20 then N'Khách hàng cấp 2'
            else N'Khách hàng thân thiết'
        end as SegmentCustomer
into CUSTOMER_GROUP
from (
    select CustomerID, count(SalesOrderID) as NumberOfOrders
    from SalesOrderHeader
    group by CustomerID
    ) as Orders

--- Tạo bảng WAIT_TIME
-- Gồm mã đơn hàng, mã khách hàng, mã nhân viên bán hàng, số tiền của đơn hàng, số thời gian chờ giữa ngày OrderDate - DueDate 
-- và cột wait_type với wait_type được tính bằng số ngày giữa OrderDate và DueDate:
-- 	wait_type >= 20: Long time
-- 	20 > wait_type  >= 5: Medium time
-- 	wait_type < 5 : Short time

select SalesOrderID, CustomerID, SalesPersonID, TotalDue,
       DATEDIFF(day, OrderDate, DueDate) as WaitTime,
       case when DATEDIFF(day, OrderDate, DueDate) < 5 then 'Short time' 
            when DATEDIFF(day, OrderDate, DueDate) < 20 then 'Medium time'
            else 'Long time'
       end as WaitType
into WAIT_TIME
from SalesOrderHeader

-- Câu 1:
-- a. Thời gian nhận hàng trung bình của từng nhóm khách hàng 

SELECT cg.SegmentCustomer, AVG(wt.WaitTime) as AverageReceiveOrderDay
from WAIT_TIME as wt
left join CUSTOMER_GROUP cg on wt.CustomerID = cg.CustomerID
group by cg.SegmentCustomer

-- b. Thời gian chờ nhận hàng lâu nhất của từng nhóm khách hàng
SELECT cg.SegmentCustomer, MAX(wt.WaitTime) as MaxReceiveOrderDay, MIN(wt.WaitTime) as MinReceiveOrderDay
from WAIT_TIME as wt
left join CUSTOMER_GROUP cg on wt.CustomerID = cg.CustomerID
group by cg.SegmentCustomer

-- Câu 2: Dựa vào bảng SalesOrderDetail.
-- Hãy tìm ra tổng số item được mua của từng đơn hàng

select SalesOrderID, sum(OrderQty) as SumOrderQty
from SalesOrderDetail
group by SalesOrderID

-- Câu 3:
-- Dựa vào bảng SalesOrderDetail, ProductSubcategory và ProductCategory.
-- Hãy tìm ra tổng doanh số của từng Category.

select pc.Name, sum(TotalDue) as SalesAmount
from SalesOrderDetail sod
left join Product p on p.ProductID = sod.ProductID
left join ProductSubcategory ps on ps.ProductSubcategoryID = p.ProductSubcategoryID
left join ProductCategory pc on ps.ProductCategoryID = pc.ProductCategoryID

-- Câu 4:
-- Hãy tính tổng doanh số của các sản phẩm được thay đổi giá bán
-- Sub query
select tp.TypeProduct, sum(sod.LineTotal) as SalesAmount
from SalesOrderDetail as sod
left join (
    select ProductID, 
        case when count(*) > 1 then 'Changed'
                else 'Unchanged'
            end as TypeProduct
    from ProductCostHistory
    group by ProductID
    ) as tp on sod.ProductID = tp.ProductID
group by tp.TypeProduct

-- Câu 5:
use MindX_Lec_3
-- a. Điểm trung bình của các học viên theo từng khoa
select cID, avg(score) as AvgScore
from LEARNING
group by cID

-- b: Điểm trung bình của các học viên theo từng môn học

select c.cName, avg(l.score) AvgScore
from LEARNING l
left join COURSE c on l.cID = c.cID
group by c.cName

-- c: Hãy đếm số lượng học viên đạt kết quả giỏi, khá và trung bình.

select 
        case when score <= 7 then N'Trung bình' 
            when score <= 8.5 then N'Khá' 
            else N'Giỏi'
        end as StudentGroup,
        count(distinct sID) as NumberOfStudents
from LEARNING
group by 
       case when score <= 7 then N'Trung bình' 
            when score <= 8.5 then N'Khá' 
            else N'Giỏi'
        end

-- d: Tìm các thông tin sau: điểm lớn nhất, điểm bé nhất, 
-- khoảng cách giữa điểm lớn nhất và điểm bé nhất của 
-- từng môn học là bao nhiêu? (Sau dấu , lấy 1 chữ số thập phân)

--Raw
select cName, max(score)
from LEARNING l
left join COURSE c on l.cID = c.cID
group by c.cName
having cName = 'BI'