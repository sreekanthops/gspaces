--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cart; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.cart (
    id integer NOT NULL,
    user_id integer,
    product_id integer,
    quantity integer DEFAULT 1
);


ALTER TABLE public.cart OWNER TO sri;

--
-- Name: cart_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.cart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_id_seq OWNER TO sri;

--
-- Name: cart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.cart_id_seq OWNED BY public.cart.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    price_at_purchase numeric(10,2) NOT NULL,
    product_name character varying(255),
    image_url character varying(255)
);


ALTER TABLE public.order_items OWNER TO sri;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO sri;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    user_id integer NOT NULL,
    order_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total_amount numeric(10,2) NOT NULL,
    status character varying(50) DEFAULT 'Pending'::character varying,
    user_email character varying(255),
    razorpay_order_id character varying(255) NOT NULL,
    razorpay_payment_id character varying(255) NOT NULL
);


ALTER TABLE public.orders OWNER TO sri;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO sri;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: product_sub_images; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.product_sub_images (
    id integer NOT NULL,
    product_id integer NOT NULL,
    image_url text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_sub_images OWNER TO sri;

--
-- Name: product_sub_images_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.product_sub_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sub_images_id_seq OWNER TO sri;

--
-- Name: product_sub_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.product_sub_images_id_seq OWNED BY public.product_sub_images.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    category text,
    price numeric,
    rating numeric,
    image_url text,
    created_by character varying(255),
    detailed_description text
);


ALTER TABLE public.products OWNER TO sri;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO sri;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer,
    username character varying(255) NOT NULL,
    rating integer,
    comment text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO sri;

--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO sri;

--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    address text,
    phone character varying(20)
);


ALTER TABLE public.users OWNER TO sri;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO sri;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: cart id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart ALTER COLUMN id SET DEFAULT nextval('public.cart_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: product_sub_images id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images ALTER COLUMN id SET DEFAULT nextval('public.product_sub_images_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: cart; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.cart (id, user_id, product_id, quantity) FROM stdin;
9	12	7	1
10	15	7	1
11	16	7	1
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.order_items (id, order_id, product_id, quantity, price_at_purchase, product_name, image_url) FROM stdin;
1	4	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
2	5	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
3	6	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
4	7	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
5	8	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
6	9	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
7	10	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
8	11	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
9	12	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
10	13	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
11	14	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
12	15	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
13	16	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
14	17	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
15	18	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
16	19	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
17	20	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
18	21	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
19	22	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
20	23	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
21	24	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.orders (id, user_id, order_date, total_amount, status, user_email, razorpay_order_id, razorpay_payment_id) FROM stdin;
4	9	2025-08-23 18:57:13.961535	1.00	Completed	sri@gmail.com	order_R8sn2pwhlyf26d	pay_R8snF3eP1pNFcA
5	14	2025-08-23 20:16:01.177902	1.00	Completed	srichityala501@gmail.com	order_R8u83hCdEGGxiW	pay_R8u8ThGoiLNCSQ
6	12	2025-08-27 15:53:56.139289	1.00	Completed	sri.chityala504@gmail.com	order_RAPnsahBFM5obN	pay_RAPo5nJs2jYAUa
7	12	2025-08-27 15:58:14.752533	1.00	Completed	sri.chityala504@gmail.com	order_RAPsPEz2y2RmSf	pay_RAPsfzu7rI5c0a
8	12	2025-08-27 16:03:32.792834	1.00	Completed	sri.chityala504@gmail.com	order_RAPy5aWg435Vip	pay_RAPyG6CrMeU92b
9	12	2025-08-27 16:09:56.675074	1.00	Completed	sri.chityala504@gmail.com	order_RAQ4nHTNhvkU6F	pay_RAQ50eT4ga4Lm2
10	12	2025-08-27 17:50:39.700312	1.00	Completed	sri.chityala504@gmail.com	order_RARmqXBIle0Oj2	pay_RARnNlvgPS8l3f
11	13	2025-09-13 17:58:17.805948	1.00	Completed	sri.chityala500@gmail.com	order_RHB0FCXTJuepdp	pay_RHB0WZgFEo6sMZ
12	13	2025-09-13 18:00:52.751262	1.00	Completed	sri.chityala500@gmail.com	order_RHB2z53jj7MkiT	pay_RHB3FOaGWvxrnU
13	13	2025-09-13 18:03:54.006192	1.00	Completed	sri.chityala500@gmail.com	order_RHB6A2oXHwXnad	pay_RHB6QwObtd7WSr
14	13	2025-09-13 18:14:37.920677	1.00	Completed	sri.chityala500@gmail.com	order_RHBHXQuhP4XZaW	pay_RHBHmKvEDNleVt
15	14	2025-09-13 18:54:27.450455	1.00	Completed	srichityala501@gmail.com	order_RHBxT8jCIONh3i	pay_RHBxr8U1eswvYR
16	14	2025-09-13 18:56:50.10443	1.00	Completed	srichityala501@gmail.com	order_RHC07bRbskaQvO	pay_RHC0L379i1eJYC
17	14	2025-09-13 19:06:05.344517	1.00	Completed	srichityala501@gmail.com	order_RHC9wHjoJJdjry	pay_RHCA8VUdLmO9V8
18	14	2025-09-13 19:10:26.598195	1.00	Completed	srichityala501@gmail.com	order_RHCEXCaX8m2b5c	pay_RHCEiLFv9apHeN
19	14	2025-09-13 19:17:17.245731	1.00	Completed	srichityala501@gmail.com	order_RHCLlQlFJetzwU	pay_RHCLy0dvBPuIKM
20	14	2025-09-13 19:26:10.335474	1.00	Completed	srichityala501@gmail.com	order_RHCV3q1MNxZRKZ	pay_RHCVLU241SrqF3
21	14	2025-09-13 19:27:31.1998	1.00	Completed	srichityala501@gmail.com	order_RHCWZ3pwAZWVIE	pay_RHCWlcr2EKARql
22	14	2025-09-13 20:00:38.429989	1.00	Completed	srichityala501@gmail.com	order_RHD5UsyjWm30JS	pay_RHD5kmmFMczGqr
23	14	2025-09-13 20:02:18.112725	1.00	Completed	srichityala501@gmail.com	order_RHD7K9BmbuO9cP	pay_RHD7USgozHDpT6
24	14	2025-09-13 20:09:01.077548	1.00	Completed	srichityala501@gmail.com	order_RHDESCQHUm7OZr	pay_RHDEcQVsb8jcgm
\.


--
-- Data for Name: product_sub_images; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.product_sub_images (id, product_id, image_url, description, created_at) FROM stdin;
22	17	img/Products/ChatGPT_Image_Sep_14_2025_10_22_06_PM.png	<b>Wooden Study Table with Spacious Worktop & Metal Legs Work</b>\r\n<li> <b>Material</b>: Plywood+ iron\r\n<li><b>Size</b>: 4x2ft\r\n\r\n	2025-09-14 16:54:42.45878
14	7	img/Products/Screenshot_2025-09-08_at_12.05.25_AM.png	Desk Lamp Black\r\nModern Minimalist Adjustable Reading Lamp Nordic Style Solid Natural Wood Metal	2025-09-07 18:43:36.134141
3	7	img/Products/Screenshot_2025-09-07_at_7.42.48_PM.png	Brand & Model: Vergo Transform Prime\r\n\r\nColor: White Grey\r\n\r\nMaterial: Premium breathable mesh seat; nylon frame\r\n\r\nDimensions: 50D x 50W x 119H cm\r\n\r\nWeight: 20 kg | Max Load: 120 kg\r\n\r\nBack Style: High back, S-shaped ergonomic mesh\r\n\r\nFeatures:\r\n\r\nAdjustable height, lumbar, headrest, and 2D armrests\r\n\r\n2:1 multi-lock synchro tilt (90°–135°)\r\n\r\n360° swivel with 60mm dual wheels\r\n\r\nHigh-density molded foam seat for thigh support\r\n\r\nStyle: Transform Prime\r\n\r\nCare: Wipe clean\r\n\r\nAssembly & Warranty: DIY (10–20 mins) | 3-year warranty\r\n\r\nExtras: Breathable mesh keeps you cool; ergonomic design improves posture and reduces back pain	2025-09-07 14:14:41.650622
4	7	img/Products/Screenshot_2025-09-08_at_12.07.38_AM.png	Framed Wall Posters/Paintings with Frame (11 x 14 inch, Multi) Set of 3 (Modern Wall Decor, 3)	2025-09-07 18:38:49.601879
17	7	img/Products/Screenshot_2025-09-14_at_12.09.11_PM.png	eather Dual Color Desk Mat 75X40cm 1.8mm Thick| Laptop Mat/Extended Large Mouse Pad, Reversible Deskspread	2025-09-09 20:00:34.508496
15	7	img/Products/Screenshot_2025-09-08_at_12.05.17_AM.png	Laptop Stand, Height-Adjustable, Foldable, Portable, Ventilated, Fits Up to 15.6-Inch Laptops (Aluminium Alloy, Silver) Tabletop	2025-09-07 18:43:53.697108
5	7	img/Products/Screenshot_2025-09-08_at_12.07.19_AM.png	Cord Organizer (160mm*80mm, Silver)	2025-09-07 18:39:35.747058
7	7	img/Products/Screenshot_2025-09-08_at_12.07.00_AM.png	Plastic Artificial Plants With Pot Leaves Hanging Ivy Garlands Plant Greenery Vine Creeper Home Decor Door Wall Balcony Decoration Party - 50 Cm (2 Pcs Money Plants)	2025-09-07 18:40:33.187298
6	7	img/Products/Screenshot_2025-09-08_at_12.07.13_AM.png	Artificial Wall Grass for Home Decoration | 50 x 50 CM | Grass Mat Panel for Vertical Garden(3 Pieces)	2025-09-07 18:40:06.893591
8	7	img/Products/Screenshot_2025-09-08_at_12.06.48_AM.png	Paris World Famous Building Small Metal Eiffel Tower Antique Vintage Statue for Gifting, Wedding,Room,Office,Decorative Showpeice for Home Decor, Desk Decor, Table Stand (15 cm)	2025-09-07 18:41:01.171151
9	7	img/Products/Screenshot_2025-09-08_at_12.06.24_AM.png	Harry Potter 3pc Set with pet Action Figure Special Edition Action Figure for Car Dashboard, Decoration, Cake, Office Desk & Study Table (Pack of 3) (Height-8 cm)	2025-09-07 18:41:24.773594
10	7	img/Products/Screenshot_2025-09-08_at_12.06.13_AM.png	Astronaut Spaceman Statue Ornament Home Office Desktop Figurine Decors Set of 3 - Golden (Golden)	2025-09-07 18:42:01.644386
16	7	img/Products/Screenshot_2025-09-08_at_12.03.49_AM.png	Vanilla Reed Diffuser Set 50ml Smoke Less Room Freshener for Home Bedroom Living Room Office\r\nVanilla & Musk Blend of Toasted Coconut 5 Rattan Reed Sticks	2025-09-07 18:44:21.410627
23	17	img/Products/Screenshot_2025-09-14_at_10.25.41_PM.png	<b>Black Round Mesh Pen Stand</b>\r\n<b>count</b>: 1 	2025-09-14 16:56:40.83064
13	7	img/Products/Screenshot_2025-09-14_at_12.09.11_PM.png	Digital Alarm Clock Table Clock for Students, Home, Office, Bedside Smart Timepiece for Heavy Sleepers, Automatic Sensor,Time,Date &Temperature, Alarm Clock for Bedroom 5 (MIROR Clock)	2025-09-07 18:43:11.505191
11	7	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-07 18:42:22.352762
25	17	img/Products/ChatGPT_Image_Sep_14_2025_10_38_08_PM.png	Wooden rafter\r\n<b>size</b>: 4x0.5ft(18mm)\r\n<b>count</b>: 3	2025-09-14 17:09:41.879254
26	17	img/Products/Screenshot_2025-09-15_at_12.26.03_AM.png	Natural plants with white pot\r\n<b>count: 4	2025-09-14 18:57:05.133432
21	17	img/Products/Screenshot_2025-09-14_at_10.04.16_PM.png	<b>Umi LED Desk Lamp – 360° Adjustable</b>\r\n<li>3 Brightness Levels\r\n<li>Eye-Caring Touch Control\r\n<li>Wireless Rechargeable	2025-09-14 16:35:12.92153
20	17	img/Products/Screenshot_2025-09-14_at_9.54.56_PM.png	<b>Fabric Study Arm Chair</b>\r\n<b>Highlights</b>\r\n<li>Adjustable Seat Height, Armrest, Wheels, Swivel\r\n<li>W x H: 75.6 cm x 98.5 cm (2 ft 5 in x 3 ft 2 in)\r\n<li>Frame Material: Plastic\r\n\r\n 	2025-09-14 16:31:05.026251
36	16	img/Products/Screenshot_2025-09-15_at_1.42.51_AM.png	<b>Rechargeable Desk Lamp with 3 Color Light Modes</b>\r\n<li>Dual LED Touch Sensor\r\n<b>Product Dimensions</b>:\t9.5D x 12.5W x 40H cms	2025-09-14 20:15:05.49618
24	17	img/Products/Screenshot_2025-09-14_at_10.29.12_PM.png	<b>PVC Wooden Panel</b>\r\nSize: 1x9ft\r\n	2025-09-14 17:00:16.386098
27	17	img/Products/Screenshot_2025-09-15_at_12.28.06_AM.png	Leather Dual Color Desk Mat 60X35cm 1.8mm Thick	2025-09-14 18:58:41.900519
28	17	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	Portronics Power Plate 7 with 6 USB Port + 8 Power Sockets Power Strip Extension Board with 2500W, 3Mtr Cord Length, 2.1A USB Output(Black), 250 Volts	2025-09-14 19:02:42.792785
29	17	img/Products/Screenshot_2025-09-15_at_12.34.51_AM.png	Aluminum Alloy Desk Grommet – Round Metal Cable Wire Hole Cover with Flip Dust-Proof Lid	2025-09-14 19:05:17.386867
30	9	img/Products/ChatGPT_Image_Sep_15_2025_12_46_24_AM.png	Modern Wooden Table\r\n<b>Table Size</b>: 4x2ft and 29inches\r\n<b>Iron Frame Thickness</b>: 25 mm x 25 mm square tubing	2025-09-14 19:20:58.207657
31	9	img/Products/Screenshot_2025-09-15_at_12.58.59_AM.png	Premium Leatherette Executive Chair | High Back Ergonomic Office Chair	2025-09-14 19:29:42.982312
32	9	img/Products/Screenshot_2025-09-15_at_1.03.10_AM.png	<b>Abstract line art black & white Wall painting </b>\r\n<b>Size</b>: 13x 19inch, set of 2	2025-09-14 19:35:01.269835
33	9	img/Products/Screenshot_2025-09-15_at_1.06.21_AM.png	<b>Gold Luxurious Table Lamp	2025-09-14 19:37:01.923779
34	9	img/Products/Screenshot_2025-09-15_at_1.08.47_AM.png	<b> Pen Holder	2025-09-14 19:39:19.46351
35	16	img/Products/Screenshot_2025-09-15_at_1.39.00_AM.png	Premium Digital Painting With Frame For Home Decor - Pack Of 3\r\n<b>Product Dimensions</b>:\t10L x 13W Cms	2025-09-14 20:10:59.507771
37	16	img/Products/Screenshot_2025-09-15_at_1.47.15_AM.png	<b>High Back Office Chair (Black)</b>	2025-09-14 20:18:58.072174
38	16	img/Products/Screenshot_2025-09-15_at_1.51.32_AM.png	<b>Wood Floating Wall Shelf</b>	2025-09-14 20:23:00.129345
39	16	img/Products/Screenshot_2025-09-15_at_1.58.39_AM.png	<b>Plants</b>\r\n<b>Units</b>: 3	2025-09-14 20:29:49.607746
40	16	img/Products/ChatGPT_Image_Sep_15_2025_01_59_52_AM.png	<b>Wooden Work Desk</b>\r\n<b>Size</b>: 5x2.25ft 29inches Height\r\n	2025-09-14 20:32:23.188493
41	10	img/Products/Screenshot_2025-09-14_at_12.08.40_PM.png	<b>Leather Dual Color Desk Mat 60X35cm 1.8mm Thick</b>	2025-09-14 20:42:13.380173
42	10	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	<b>Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-14 20:45:21.217541
43	10	img/Products/Screenshot_2025-09-15_at_2.16.13_AM.png	<b>EBCO Cable Organizer - ZINC(60MM)	2025-09-14 20:46:33.11741
44	10	img/Products/Screenshot_2025-09-15_at_2.16.46_AM.png	<b>Vanilla Reed Diffuser Set 50ml Smoke Less Room Freshener	2025-09-14 20:47:16.419606
45	10	img/Products/Screenshot_2025-09-15_at_2.17.32_AM.png	<b>Foldable & Portable Laptop Riser Stand Made with Aluminum Alloy	2025-09-14 20:47:56.927053
46	10	img/Products/Screenshot_2025-09-15_at_2.18.10_AM.png	<b>Desk Lamp Black	2025-09-14 20:48:36.256188
47	10	img/Products/Screenshot_2025-09-15_at_2.19.05_AM.png	<b>Digital Alarm Clock Table Clock	2025-09-14 20:49:19.127837
48	10	img/Products/Screenshot_2025-09-15_at_2.19.35_AM.png	<b>Desk Organizer Desk Accessories Stand for Home/Office, White	2025-09-14 20:50:13.513154
49	10	img/Products/Screenshot_2025-09-15_at_2.20.25_AM.png	<b>Harry Potter 3pc Set with pet Action Figure Special Edition-Height-8 cm	2025-09-14 20:50:51.323341
50	10	img/Products/Screenshot_2025-09-15_at_2.12.31_AM.png	<b>Quotes Frames - Motivational Quotes Rectangular Wall Frames For Office - (14 X 11 Inches), Black	2025-09-14 20:52:00.763804
51	10	img/Products/Screenshot_2025-09-15_at_2.23.32_AM.png	<b>High Back Ergonomic Chair, 3D Armrest, Aluminum Base, Home, Study, Premium Mesh, Fabric Office Adjustable Arm Chair 	2025-09-14 20:54:20.750823
52	10	img/Products/Screenshot_2025-09-15_at_2.25.30_AM.png	<b> 4 Pcs Miniature Showpiece Set	2025-09-14 20:55:53.811052
53	10	img/Products/Screenshot_2025-09-15_at_2.25.58_AM.png	<b>Astronaut Spaceman Statue Ornament Home Office Desktop Figurine Decors Set of 3 - Golden	2025-09-14 20:56:24.221345
54	10	img/Products/Screenshot_2025-09-15_at_2.26.57_AM.png	<b>Palm Air Purifier Live Plant Natural Indoor and Outdoor Air Purifying Plant	2025-09-14 20:57:24.134627
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.products (id, name, description, category, price, rating, image_url, created_by, detailed_description) FROM stdin;
10	Neo Ergonomic Desk		executive	58000.0	5.0	img/Products/IMG_9230.JPG	sri@gmail.com	\N
9	Scandi Minimal		minimalist	35000	5.0	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg	sri@gmail.com	\N
7	Green Wall Desk 		ergonomic	65000	5.0	img/Products/1000397805.jpg	sri@gmail.com	Nature
11	Dual Harmony		couple	99000.0	5.0	img/Products/dualdesks.jpg	sri@gmail.com	\N
17	Elegant Corner		executive	50000.0	5.0	img/Products/17/17.jpg	srichityala501@gmail.com	\N
16	Beige Minds		executive	48000.0	5.0	img/Products/Screenshot_2025-09-15_at_1.36.31_AM.png	srichityala501@gmail.com	\N
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.reviews (id, product_id, user_id, username, rating, comment, created_at) FROM stdin;
1	7	\N	sri@gmail.com	5	Very comfortable 	2025-08-16 17:41:13.894303
2	7	14	chityala srikanth	4	good	2025-08-24 09:42:23.63162
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.users (id, name, email, password, address, phone) FROM stdin;
9	sri	sri@gmail.com	sri	\N	\N
10	Syed Ahmed	syed.ahmed8801302@gmail.com	aTNkZUoq	\N	\N
11	syed	syed@gmail.com	syed	\N	\N
12	Home	sri.chityala504@gmail.com		\N	\N
13	Sri ch	sri.chityala500@gmail.com	hello	\N	\N
15	Sreekanth Devops	sreekanththetechie@gmail.com	oauth_user_no_password_6lUorcIT7qfGlC3V	\N	\N
16	yamini chityala	chityalayamini@gmail.com	oauth_user_no_password_d69XXaVVlKg5aIG2	\N	\N
14	chityala srikanth	srichityala501@gmail.com			7075077384
\.


--
-- Name: cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.cart_id_seq', 28, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.order_items_id_seq', 21, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.orders_id_seq', 24, true);


--
-- Name: product_sub_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_sub_images_id_seq', 54, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.products_id_seq', 17, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.reviews_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.users_id_seq', 16, true);


--
-- Name: cart cart_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_pkey PRIMARY KEY (id);


--
-- Name: cart cart_user_product_unique; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_user_product_unique UNIQUE (user_id, product_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: orders orders_razorpay_order_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_razorpay_order_id_key UNIQUE (razorpay_order_id);


--
-- Name: orders orders_razorpay_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_razorpay_payment_id_key UNIQUE (razorpay_payment_id);


--
-- Name: product_sub_images product_sub_images_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images
    ADD CONSTRAINT product_sub_images_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: cart cart_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: cart cart_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: orders orders_user_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_email_fkey FOREIGN KEY (user_email) REFERENCES public.users(email);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: product_sub_images product_sub_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images
    ADD CONSTRAINT product_sub_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

