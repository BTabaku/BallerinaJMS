create schema booking;

create table booking
(
	BookingID int auto_increment,
	BookingNo int not null,
	BookingDate datetime null,
	Receiver char(20) not null,
	LoadDate datetime null,
	UnloadDate datetime null,
	ShipName char(20) null,
	PortOfLoad char(20) null,
	PortOfUnload char(20) null,
	DBInsertTime datetime null,
	DBUpdateTime datetime null,
	DBDeleted tinyint(20) null,
	constraint booking_BookingID_uindex
		unique (BookingID),
	constraint booking_BookingNo_uindex
		unique (BookingNo)
);

alter table booking
	add primary key (BookingID);

create table bookingcontainers
(
    BookingNo    int      null,
    Container    char(20) not null,
    Temperature  int      not null,
    OtherDetails longtext null,
    constraint bookingcontainers_booking_BookingNo_fk
        foreign key (BookingNo) references booking (BookingNo)
);



