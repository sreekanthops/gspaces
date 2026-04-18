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

--
-- Name: auto_generate_referral_code(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.auto_generate_referral_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code(NEW.name, NEW.id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_generate_referral_code() OWNER TO sri;

--
-- Name: generate_referral_code(text, integer); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.generate_referral_code(user_name text, user_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_code VARCHAR(20);
    final_code VARCHAR(20);
    counter INTEGER := 0;
BEGIN
    -- Create base code from username (first 6 chars uppercase + user_id)
    base_code := UPPER(SUBSTRING(REGEXP_REPLACE(user_name, '[^a-zA-Z0-9]', '', 'g'), 1, 6)) || user_id;
    final_code := base_code;
    
    -- Check if code exists and add counter if needed
    WHILE EXISTS (SELECT 1 FROM users WHERE referral_code = final_code) LOOP
        counter := counter + 1;
        final_code := base_code || counter;
    END LOOP;
    
    RETURN final_code;
END;
$$;


ALTER FUNCTION public.generate_referral_code(user_name text, user_id integer) OWNER TO sri;

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
-- Name: coupon_usage; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.coupon_usage (
    id integer NOT NULL,
    coupon_id integer NOT NULL,
    user_id integer NOT NULL,
    order_id integer,
    discount_applied numeric(10,2) NOT NULL,
    used_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    discount_amount numeric(10,2) DEFAULT 0.00,
    referrer_bonus_amount numeric(10,2) DEFAULT 0.00,
    coupon_code character varying(50)
);


ALTER TABLE public.coupon_usage OWNER TO sri;

--
-- Name: TABLE coupon_usage; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.coupon_usage IS 'Tracks coupon usage to prevent duplicate usage by same user';


--
-- Name: coupon_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.coupon_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coupon_usage_id_seq OWNER TO sri;

--
-- Name: coupon_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.coupon_usage_id_seq OWNED BY public.coupon_usage.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    discount_type character varying(20) NOT NULL,
    discount_value numeric(10,2) NOT NULL,
    description text,
    min_order_amount numeric(10,2) DEFAULT 0,
    max_discount_amount numeric(10,2),
    is_active boolean DEFAULT true,
    usage_limit integer,
    times_used integer DEFAULT 0,
    valid_from timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    valid_until timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(255),
    user_id integer,
    is_personal boolean DEFAULT false,
    CONSTRAINT coupons_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['percentage'::character varying, 'fixed'::character varying])::text[])))
);


ALTER TABLE public.coupons OWNER TO sri;

--
-- Name: COLUMN coupons.user_id; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.coupons.user_id IS 'If NULL, coupon is public. If set, coupon is personal and only that user can use it.';


--
-- Name: COLUMN coupons.is_personal; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.coupons.is_personal IS 'TRUE if coupon is personal (user-specific), FALSE if public (everyone can use)';


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coupons_id_seq OWNER TO sri;

--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: discount; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.discount (
    id integer NOT NULL,
    discount_percent numeric(5,2) NOT NULL
);


ALTER TABLE public.discount OWNER TO sri;

--
-- Name: discount_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.discount_id_seq OWNER TO sri;

--
-- Name: discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.discount_id_seq OWNED BY public.discount.id;


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
    image_url character varying(255),
    deal_discount numeric DEFAULT 0,
    coupon_discount numeric DEFAULT 0,
    product_link character varying(500)
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
    razorpay_payment_id character varying(255) NOT NULL,
    coupon_code character varying(50),
    discount_amount numeric(10,2) DEFAULT 0,
    deal_discount numeric DEFAULT 0,
    coupon_discount numeric DEFAULT 0,
    status_code character varying(50),
    status_updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    shipping_name character varying(255),
    shipping_phone character varying(50),
    shipping_address_line_1 character varying(255),
    shipping_address_line_2 character varying(255),
    shipping_city character varying(120),
    shipping_state character varying(120),
    shipping_pincode character varying(20),
    shipping_country character varying(120),
    delivery_instructions text,
    company_name character varying(255),
    gstin character varying(30),
    wallet_amount_used numeric(10,2) DEFAULT 0.00,
    final_paid_amount numeric(10,2),
    cashback_earned numeric(10,2) DEFAULT 0.00,
    cashback_credited boolean DEFAULT false
);


ALTER TABLE public.orders OWNER TO sri;

--
-- Name: COLUMN orders.wallet_amount_used; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.orders.wallet_amount_used IS 'Amount paid from wallet for this order';


--
-- Name: COLUMN orders.cashback_earned; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.orders.cashback_earned IS 'Cashback earned on first order (5% of order value)';


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
-- Name: otp_verifications; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.otp_verifications (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    otp_code character varying(6) NOT NULL,
    name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    attempts integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone NOT NULL,
    verified boolean DEFAULT false
);


ALTER TABLE public.otp_verifications OWNER TO sri;

--
-- Name: otp_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.otp_verifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.otp_verifications_id_seq OWNER TO sri;

--
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


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
    detailed_description text,
    deal_percent numeric DEFAULT 0
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
-- Name: referral_coupons; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.referral_coupons (
    id integer NOT NULL,
    user_id integer NOT NULL,
    coupon_code character varying(20) NOT NULL,
    discount_percentage numeric(5,2) DEFAULT 5.00,
    referral_bonus_percentage numeric(5,2) DEFAULT 5.00,
    times_used integer DEFAULT 0,
    total_referral_earnings numeric(10,2) DEFAULT 0.00,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    discount_type character varying(20) DEFAULT 'percentage'::character varying,
    discount_amount numeric(10,2) DEFAULT 0.00,
    referrer_bonus_type character varying(20) DEFAULT 'percentage'::character varying,
    referrer_bonus_amount numeric(10,2) DEFAULT 0.00,
    min_order_amount numeric(10,2) DEFAULT 0.00,
    max_discount_amount numeric(10,2),
    first_order_only boolean DEFAULT false,
    usage_limit integer,
    per_user_limit integer DEFAULT 1,
    description text
);


ALTER TABLE public.referral_coupons OWNER TO sri;

--
-- Name: TABLE referral_coupons; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.referral_coupons IS 'User-specific referral codes with 1-month expiry';


--
-- Name: referral_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.referral_coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.referral_coupons_id_seq OWNER TO sri;

--
-- Name: referral_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.referral_coupons_id_seq OWNED BY public.referral_coupons.id;


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
    phone character varying(20),
    profile_photo character varying(255),
    address_line_2 character varying(255),
    city character varying(120),
    state character varying(120),
    pincode character varying(20),
    country character varying(120),
    landmark character varying(255),
    alternate_phone character varying(50),
    company_name character varying(255),
    gstin character varying(30),
    wallet_balance numeric(10,2) DEFAULT 0.00,
    wallet_bonus_limit numeric(10,2) DEFAULT 10000.00,
    referral_code character varying(20),
    referred_by_user_id integer,
    signup_bonus_credited boolean DEFAULT false,
    first_order_completed boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO sri;

--
-- Name: COLUMN users.wallet_balance; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.wallet_balance IS 'Current wallet balance available for use';


--
-- Name: COLUMN users.wallet_bonus_limit; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.wallet_bonus_limit IS 'Maximum bonus amount that can be used per order (default 10000)';


--
-- Name: COLUMN users.referral_code; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.referral_code IS 'Unique referral code for each user';


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
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.wallet_transactions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    transaction_type character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    balance_after numeric(10,2) NOT NULL,
    description text,
    reference_type character varying(50),
    reference_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb
);


ALTER TABLE public.wallet_transactions OWNER TO sri;

--
-- Name: TABLE wallet_transactions; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.wallet_transactions IS 'Tracks all wallet transactions including credits, debits, bonuses, and referrals';


--
-- Name: wallet_summary; Type: VIEW; Schema: public; Owner: sri
--

CREATE VIEW public.wallet_summary AS
 SELECT u.id AS user_id,
    u.name,
    u.email,
    u.wallet_balance,
    u.wallet_bonus_limit,
    u.referral_code,
    rc.times_used AS referral_uses,
    rc.total_referral_earnings,
    count(DISTINCT wt.id) AS total_transactions,
    COALESCE(sum(
        CASE
            WHEN ((wt.transaction_type)::text = 'credit'::text) THEN wt.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_credits,
    COALESCE(sum(
        CASE
            WHEN ((wt.transaction_type)::text = 'debit'::text) THEN wt.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_debits
   FROM ((public.users u
     LEFT JOIN public.referral_coupons rc ON ((u.id = rc.user_id)))
     LEFT JOIN public.wallet_transactions wt ON ((u.id = wt.user_id)))
  GROUP BY u.id, u.name, u.email, u.wallet_balance, u.wallet_bonus_limit, u.referral_code, rc.times_used, rc.total_referral_earnings;


ALTER VIEW public.wallet_summary OWNER TO sri;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.wallet_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallet_transactions_id_seq OWNER TO sri;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.wallet_transactions_id_seq OWNED BY public.wallet_transactions.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.wallets (
    id integer NOT NULL,
    user_id integer NOT NULL,
    balance numeric(10,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_balance CHECK ((balance >= (0)::numeric))
);


ALTER TABLE public.wallets OWNER TO sri;

--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.wallets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_id_seq OWNER TO sri;

--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: cart id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart ALTER COLUMN id SET DEFAULT nextval('public.cart_id_seq'::regclass);


--
-- Name: coupon_usage id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage ALTER COLUMN id SET DEFAULT nextval('public.coupon_usage_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: discount id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount ALTER COLUMN id SET DEFAULT nextval('public.discount_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: otp_verifications id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.otp_verifications ALTER COLUMN id SET DEFAULT nextval('public.otp_verifications_id_seq'::regclass);


--
-- Name: product_sub_images id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images ALTER COLUMN id SET DEFAULT nextval('public.product_sub_images_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: referral_coupons id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons ALTER COLUMN id SET DEFAULT nextval('public.referral_coupons_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wallet_transactions id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions ALTER COLUMN id SET DEFAULT nextval('public.wallet_transactions_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Data for Name: cart; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.cart (id, user_id, product_id, quantity) FROM stdin;
89	13	30	1
95	14	30	1
96	31	30	1
97	32	30	1
11	16	7	1
77	21	10	1
\.


--
-- Data for Name: coupon_usage; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupon_usage (id, coupon_id, user_id, order_id, discount_applied, used_at, discount_amount, referrer_bonus_amount, coupon_code) FROM stdin;
\.


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupons (id, code, discount_type, discount_value, description, min_order_amount, max_discount_amount, is_active, usage_limit, times_used, valid_from, valid_until, created_at, created_by, user_id, is_personal) FROM stdin;
5	PERSONAL_SRI501_6187	fixed	500.00	bonus	0.00	\N	t	\N	0	2026-04-18 14:32:13.066897	2026-07-17 14:32:13.06884	2026-04-18 14:32:13.066897	srichityala501@gmail.com	30	t
2	DEEWALIFEST	percentage	2.00	2% Diwali festival discount	0.00	\N	f	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
3	DASARAFEST	fixed	1000.00	₹1000 off on Dasara festival	0.00	\N	f	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
1	NEWGSPACES	fixed	1000.00	1000 discount for new customers	0.00	\N	t	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
4	SRI2026	fixed	5000.00		0.00	\N	f	\N	0	2026-04-15 08:14:34.387663	\N	2026-04-15 08:14:34.387663	srichityala501@gmail.com	\N	f
6	BONUS_SRI1_EX9E	fixed	500.00	bonus	0.00	\N	t	\N	0	2026-04-18 14:39:14.405344	2026-07-17 14:39:14.407262	2026-04-18 14:39:14.405344	srichityala501@gmail.com	31	t
7	BONUS_GSPACES_FCC4	fixed	500.00	Personal coupon for gspaces	0.00	\N	t	\N	0	2026-04-18 14:52:25.891663	2026-07-17 14:52:25.893566	2026-04-18 14:52:25.891663	srichityala501@gmail.com	32	t
\.


--
-- Data for Name: discount; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.discount (id, discount_percent) FROM stdin;
58	10.00
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.order_items (id, order_id, product_id, quantity, price_at_purchase, product_name, image_url, deal_discount, coupon_discount, product_link) FROM stdin;
1	4	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
2	5	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
3	6	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
4	7	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
5	8	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
6	9	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
7	10	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
43	52	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	\N
44	53	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	\N
45	54	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
46	55	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
47	56	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
48	57	30	1	0.90	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.orders (id, user_id, order_date, total_amount, status, user_email, razorpay_order_id, razorpay_payment_id, coupon_code, discount_amount, deal_discount, coupon_discount, status_code, status_updated_at, shipping_name, shipping_phone, shipping_address_line_1, shipping_address_line_2, shipping_city, shipping_state, shipping_pincode, shipping_country, delivery_instructions, company_name, gstin, wallet_amount_used, final_paid_amount, cashback_earned, cashback_credited) FROM stdin;
54	14	2026-04-11 04:21:05.979416	1.18	Confirmed	srichityala501@gmail.com	order_Sc3GDd4Ow8k9t1	pay_Sc3GWgrF73RTqh	\N	0.00	0	0	confirmed	2026-04-11 04:21:05.979413	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
4	9	2025-08-23 18:57:13.961535	1.00	Completed	sri@gmail.com	order_R8sn2pwhlyf26d	pay_R8snF3eP1pNFcA	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
5	14	2025-08-23 20:16:01.177902	1.00	Completed	srichityala501@gmail.com	order_R8u83hCdEGGxiW	pay_R8u8ThGoiLNCSQ	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
6	12	2025-08-27 15:53:56.139289	1.00	Completed	sri.chityala504@gmail.com	order_RAPnsahBFM5obN	pay_RAPo5nJs2jYAUa	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
7	12	2025-08-27 15:58:14.752533	1.00	Completed	sri.chityala504@gmail.com	order_RAPsPEz2y2RmSf	pay_RAPsfzu7rI5c0a	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
12	13	2025-09-13 18:00:52.751262	1.00	Completed	sri.chityala500@gmail.com	order_RHB2z53jj7MkiT	pay_RHB3FOaGWvxrnU	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
8	12	2025-08-27 16:03:32.792834	1.00	Completed	sri.chityala504@gmail.com	order_RAPy5aWg435Vip	pay_RAPyG6CrMeU92b	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
32	14	2025-09-20 22:13:44.465179	1.18	Completed	srichityala501@gmail.com	order_RK163re8qx5JA7	pay_RK16BovwJLIOrW	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
33	14	2025-09-20 22:15:36.872055	1.18	Completed	srichityala501@gmail.com	order_RK17xDUYkH1IKq	pay_RK187buEqFtdUv	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
34	14	2025-09-20 22:18:00.334563	1.18	Completed	srichityala501@gmail.com	order_RK1AZ2a3G75qwz	pay_RK1AhFe1mMj2so	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
35	12	2025-09-20 22:25:29.49738	1.18	Completed	sri.chityala504@gmail.com	order_RK1IKnNGtXFcu1	pay_RK1IbzlhTASqMU	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
13	13	2025-09-13 18:03:54.006192	1.00	Completed	sri.chityala500@gmail.com	order_RHB6A2oXHwXnad	pay_RHB6QwObtd7WSr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
52	14	2026-04-10 06:52:46.51459	1.18	Completed	srichityala501@gmail.com	order_SbhIaGm9yqc70T	pay_SbhJa3WIAwl3dP	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
36	12	2025-09-21 07:26:50.713964	1.18	Completed	sri.chityala504@gmail.com	order_RKAWCD2wlJUDZ7	pay_RKAWTB4m0jYocZ	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
9	12	2025-08-27 16:09:56.675074	1.00	Completed	sri.chityala504@gmail.com	order_RAQ4nHTNhvkU6F	pay_RAQ50eT4ga4Lm2	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
37	12	2025-09-21 07:31:15.296914	1.18	Completed	sri.chityala504@gmail.com	order_RKAaubx1p1ItXJ	pay_RKAb6xwZluq5mE	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
38	12	2025-09-21 07:32:05.502801	1.18	Completed	sri.chityala504@gmail.com	order_RKAbgu3CDEb3qm	pay_RKAc02XD6IiAwH	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
55	14	2026-04-11 04:24:39.717182	1.18	Confirmed	srichityala501@gmail.com	order_Sc3K3Lk5SMEQMI	pay_Sc3KJQUjr8I2D5	\N	0.00	0	0	confirmed	2026-04-11 04:24:39.717178	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
10	12	2025-08-27 17:50:39.700312	1.00	Completed	sri.chityala504@gmail.com	order_RARmqXBIle0Oj2	pay_RARnNlvgPS8l3f	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
53	13	2026-04-10 07:21:04.533738	1.18	Completed	sri.chityala500@gmail.com	order_Sbhn040nzYCWFc	pay_SbhnWt5OfnlGf9	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
56	14	2026-04-11 04:29:53.848714	1.18	Delivered	srichityala501@gmail.com	order_Sc3PVrd41W2gY0	pay_Sc3PoFFe4a74U9	\N	0.00	0	0	delivered	2026-04-15 08:11:58.590029	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
21	14	2025-09-13 19:27:31.1998	1.00	Completed	srichityala501@gmail.com	order_RHCWZ3pwAZWVIE	pay_RHCWlcr2EKARql	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
22	14	2025-09-13 20:00:38.429989	1.00	Completed	srichityala501@gmail.com	order_RHD5UsyjWm30JS	pay_RHD5kmmFMczGqr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
23	14	2025-09-13 20:02:18.112725	1.00	Completed	srichityala501@gmail.com	order_RHD7K9BmbuO9cP	pay_RHD7USgozHDpT6	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
24	14	2025-09-13 20:09:01.077548	1.00	Completed	srichityala501@gmail.com	order_RHDESCQHUm7OZr	pay_RHDEcQVsb8jcgm	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
11	13	2025-09-13 17:58:17.805948	1.00	Completed	sri.chityala500@gmail.com	order_RHB0FCXTJuepdp	pay_RHB0WZgFEo6sMZ	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
57	14	2026-04-11 06:58:12.742372	1.06	Delivered	srichityala501@gmail.com	order_Sc5w5pnDnWdwjm	pay_Sc5wSBlupwDrkf	\N	0.00	0	0	delivered	2026-04-11 07:14:07.886298	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
25	14	2025-09-20 15:49:29.600576	1.18	Completed	srichityala501@gmail.com	order_RJuY4dXif8w5I5	pay_RJuYJhkb54cnFo	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
26	14	2025-09-20 15:56:40.969307	1.18	Completed	srichityala501@gmail.com	order_RJufdLmlBvc3Ju	pay_RJufsy9MhV9v2Q	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
27	14	2025-09-20 21:44:30.015326	1.18	Completed	srichityala501@gmail.com	order_RK0b1S3qtTNas9	pay_RK0bII0mDzvvMc	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
28	14	2025-09-20 21:49:23.097919	1.18	Completed	srichityala501@gmail.com	order_RK0gCeIuR98nHr	pay_RK0gSR3gD5tqMx	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
29	14	2025-09-20 21:55:14.750662	1.18	Completed	srichityala501@gmail.com	order_RK0mT1oKWB8RLT	pay_RK0meyoBKGyLrW	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
30	14	2025-09-20 22:08:06.760943	1.00	Completed	srichityala501@gmail.com	order_RK0zz1uilbQHvj	pay_RK10GHnI7ZCyP7	\N	0.15	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
31	14	2025-09-20 22:10:36.104491	1.18	Completed	srichityala501@gmail.com	order_RK12hVyoQu8hSv	pay_RK12raFnZxKU84	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
14	13	2025-09-13 18:14:37.920677	1.00	Completed	sri.chityala500@gmail.com	order_RHBHXQuhP4XZaW	pay_RHBHmKvEDNleVt	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
15	14	2025-09-13 18:54:27.450455	1.00	Completed	srichityala501@gmail.com	order_RHBxT8jCIONh3i	pay_RHBxr8U1eswvYR	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
16	14	2025-09-13 18:56:50.10443	1.00	Completed	srichityala501@gmail.com	order_RHC07bRbskaQvO	pay_RHC0L379i1eJYC	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
17	14	2025-09-13 19:06:05.344517	1.00	Completed	srichityala501@gmail.com	order_RHC9wHjoJJdjry	pay_RHCA8VUdLmO9V8	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
18	14	2025-09-13 19:10:26.598195	1.00	Completed	srichityala501@gmail.com	order_RHCEXCaX8m2b5c	pay_RHCEiLFv9apHeN	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
19	14	2025-09-13 19:17:17.245731	1.00	Completed	srichityala501@gmail.com	order_RHCLlQlFJetzwU	pay_RHCLy0dvBPuIKM	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
20	14	2025-09-13 19:26:10.335474	1.00	Completed	srichityala501@gmail.com	order_RHCV3q1MNxZRKZ	pay_RHCVLU241SrqF3	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
39	12	2025-09-21 07:35:01.223395	1.18	Completed	sri.chityala504@gmail.com	order_RKAer4beH9tcxD	pay_RKAf4kWFuyEC6U	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
40	12	2025-09-21 07:39:39.645275	1.18	Completed	sri.chityala504@gmail.com	order_RKAjeVX4aADdtR	pay_RKAjzrA8rNsmji	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
41	14	2025-09-21 07:45:21.288893	1.18	Completed	srichityala501@gmail.com	order_RKApjUNjEhP6S0	pay_RKAq02mcEsKuti	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
43	14	2025-09-21 12:44:58.897377	1.18	Completed	srichityala501@gmail.com	order_RKFwEUlQ1yAlWi	pay_RKFwVFhPR6qVfN	\N	0.00	0.00	0.00	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
49	14	2025-10-12 18:19:06.555201	1.18	Completed	srichityala501@gmail.com	order_RSeqiQvsHN5uJd	pay_RSeqzdSQHqfJSX	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
50	14	2025-10-12 18:30:37.234285	1.18	Completed	srichityala501@gmail.com	order_RSf2rYm4k5RkKo	pay_RSf39bi7eJBSK2	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
51	14	2025-10-12 18:32:01.761722	1.42	Completed	srichityala501@gmail.com	order_RSf4QOuwurvfRF	pay_RSf4e10ZAg5EXr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
\.


--
-- Data for Name: otp_verifications; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.otp_verifications (id, email, otp_code, name, password, attempts, created_at, expires_at, verified) FROM stdin;
2	test@gmail.com	522255	test	998969	0	2026-04-18 11:13:58.351503	2026-04-18 11:18:58.351462	f
\.


--
-- Data for Name: product_sub_images; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.product_sub_images (id, product_id, image_url, description, created_at) FROM stdin;
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
20	17	img/Products/Screenshot_2025-09-14_at_9.54.56_PM.png	<b>Fabric Study Arm Chair</b>\r\n<b>Highlights</b>\r\n<li>Adjustable Seat Height, Armrest, Wheels, Swivel\r\n<li>W x H: 75.6 cm x 98.5 cm (2 ft 5 in x 3 ft 2 in)\r\n<li>Frame Material: Plastic\r\n\r\n 	2025-09-14 16:31:05.026251
24	17	img/Products/Screenshot_2025-09-14_at_10.29.12_PM.png	<b>PVC Wooden Panel</b>\r\nSize: 1x9ft\r\n	2025-09-14 17:00:16.386098
27	17	img/Products/Screenshot_2025-09-15_at_12.28.06_AM.png	Leather Dual Color Desk Mat 60X35cm 1.8mm Thick	2025-09-14 18:58:41.900519
28	17	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	Portronics Power Plate 7 with 6 USB Port + 8 Power Sockets Power Strip Extension Board with 2500W, 3Mtr Cord Length, 2.1A USB Output(Black), 250 Volts	2025-09-14 19:02:42.792785
29	17	img/Products/Screenshot_2025-09-15_at_12.34.51_AM.png	Aluminum Alloy Desk Grommet – Round Metal Cable Wire Hole Cover with Flip Dust-Proof Lid	2025-09-14 19:05:17.386867
41	10	img/Products/Screenshot_2025-09-14_at_12.08.40_PM.png	<b>Leather Dual Color Desk Mat 60X35cm 1.8mm Thick</b>	2025-09-14 20:42:13.380173
42	10	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	<b>Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-14 20:45:21.217541
64	28	img/Products/Screenshot_2026-04-03_at_1.57.11_PM.png	Plant with 2ft height	2026-04-02 21:55:52.678026
22	17	img/Products/Office_Desk_Unit.png	<b>Wooden Study Table with 3 Layered Storage box</b>\r\n<li> <b>Material</b>: Plywood+ iron\r\n<li><b>Size</b>: 4x2ft\r\n\r\n	2025-09-14 16:54:42.45878
21	17	img/Products/White_Desk_Lamp.png	<b>White Desk Lamp</b>\r\n	2025-09-14 16:35:12.92153
25	17	img/Products/Illuminated_Shelves.png	Wooden rafter with Profile light\r\n<b>size</b>: 4x0.5ft(18mm)\r\n<b>count</b>: 3	2025-09-14 17:09:41.879254
26	17	img/Products/Screenshot_2025-09-15_at_12.26.03_AM.png	Natural plants with white pot\r\n<b>count: 4(Including Big Plant	2025-09-14 18:57:05.133432
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
91	25	img/Products/Wall_Mounted_Shelf_1.png	wall mounted box rack\r\nsize: 3x0.5ft and 8inch height	2026-04-03 07:45:56.075466
59	7	img/Products/ChatGPT_Image_Oct_17_2025_09_31_54_PM-Photoroom.png	Size: 5x2.25 ft 29inches height\r\n	2025-10-17 16:10:01.990393
60	28	img/Products/28/28_sub1.jpg	4x2 table size with white board and black legs	2026-04-02 21:55:52.678026
61	28	img/Products/28/28_sub2.jpg	Ergonomic chair with head rest \r\ncolour: Black	2026-04-02 21:55:52.678026
65	28	img/Products/28/28_sub6.jpg	Table plant	2026-04-02 21:55:52.678026
63	28	img/Products/28/28_sub4.jpg	12x15inches frame x2	2026-04-02 21:55:52.678026
66	29	img/Products/29/29_sub1.jpg	Table Size: 4x2ft 29'inches with white storage box	2026-04-02 22:05:22.996036
68	29	img/Products/29/29_sub3.jpg	Black Ergonomic Chair with Headrest\r\n	2026-04-02 22:05:22.996036
69	29	img/Products/29/29_sub4.jpg	Table Plants x4 units	2026-04-02 22:05:22.996036
71	29	img/Products/29/29_sub6.jpg	White Table lamp	2026-04-02 22:05:22.996036
62	28	img/Products/28/28_sub3.jpg	6x3inch black pen holder	2026-04-02 21:55:52.678026
72	22	img/Products/Modern_Desk_Unit.png	Wood Material: 701 grade Plywood\r\nsize: 5x2ft and 29' inch height\r\n4 Layered storage box	2026-04-03 06:51:59.878702
76	22	img/Products/Gray_Area_Rug.png	5x5 size fabric carpet	2026-04-03 06:57:10.738323
77	22	img/Products/Monochromatic_Landscape_Art.png	15x18 size frame	2026-04-03 06:57:39.202431
75	22	img/Products/Floating_Shelf_Display_1.png	White colour wooden rack	2026-04-03 06:56:04.33244
78	22	img/Products/Potted_Shelf_Plant.png	Mini plant with white pot	2026-04-03 07:06:01.080981
79	22	img/Products/Pen_Holder.png	6x3inches pen holder	2026-04-03 07:06:35.920774
81	24	img/Products/Dual_Black_Desk.png	Table: 8x2ft + 29' inch height \r\n3 layered storage\r\ncolour: black	2026-04-03 07:16:22.756417
92	25	img/Products/Large_Animal_Print.png	beige coloured frame\r\nsize: 15x18inches\r\nAdditional: mini frames\r\nunits: 3	2026-04-03 07:47:13.682368
93	25	img/Products/Golden_Metallic_Lamp.png	Gold coloured table lamp\r\nunit: 1	2026-04-03 07:48:32.285802
83	24	img/Products/Distressed_Gray_Rug.png	8x4ft carpet	2026-04-03 07:20:27.57703
82	24	img/Products/Desk_Mat_with_Peripherals_1.png	Deskmat\r\nunits: 2\r\nsize: 11x23inches\r\ncolour: cream	2026-04-03 07:18:22.038767
80	24	img/Products/Black_Desk_Lamp_1.png	gold coloured table lamp with warm light\r\nunits: 2	2026-04-03 07:14:53.980098
85	24	img/Products/Beige_Office_Chair.png	Roller soft chair\r\nunits: 2\r\ncolour: cream	2026-04-03 07:25:33.116993
86	24	img/Products/Empty_Floating_Shelves.png	wooden wall mounted racks\r\nunits: 4(2ft)\r\nhalf sized racks: 2(1ft)	2026-04-03 07:28:55.621355
87	24	img/Products/Assorted_Shelf_Plants.png	mini plants\r\nunits: 4	2026-04-03 07:29:38.84303
84	24	img/Products/Misty_Mountains_Art.png	12x24inches black bordered frame\r\nunit: 1\r\nAnd additional frame in multisize\r\nunits: 4	2026-04-03 07:21:27.062685
88	24	img/Products/Pen_Holder.png	pen holder\r\nsize: 6x3inch\r\nunits: 2	2026-04-03 07:34:16.876031
89	25	img/Products/Dual_Desk_Setup.png	Dual Table with storage\r\ntable size: 4x2ft 29' inch height\r\nstorage size: 1x1ft  29' inch height\r\ndraws: 4	2026-04-03 07:41:46.757228
90	25	img/Products/Ergonomic_Office_Chair.png	soft sitting ergonomic chair\r\nunits: 2	2026-04-03 07:42:30.211657
94	25	img/Products/Potted_Snake_Plant.png	table plant\r\nunits: 1\r\nAdditional: mini plants\r\nunits: 3	2026-04-03 07:49:17.778793
95	25	img/Products/Black_Mesh_Pen_Holder_1.png	pen holder:\r\nsize: 6x3inches\r\nunits: 2	2026-04-03 07:51:36.036375
96	23	img/Products/Ergonomic_Office_Chair.png	black seated ergonomic chair	2026-04-03 07:55:55.11201
97	23	img/Products/Natural_Wood_Desk.png	wooden table\r\nsize: 4x2ft 29'inch height	2026-04-03 07:56:31.835042
98	23	img/Products/Potted_Desk_Plants.png	plants\r\nunits: 3	2026-04-03 07:56:52.790266
99	23	img/Products/Large_Floor_Plants.png	plants dark brown colour\r\nunits: 2\r\nAdditional plants\r\nunits: 4	2026-04-03 07:57:19.336447
100	23	img/Products/Adjustable_Desk_Lamp.png	black table lamp	2026-04-03 07:58:00.943323
101	23	img/Products/Vertical_Garden_Wall.png	wall garden	2026-04-03 07:58:26.089716
102	26	img/Products/Executive_Desk.png	Wooden storage table\r\nsize: 5x2.25ft 29' inch height	2026-04-03 08:05:32.478653
103	26	img/Products/Illuminated_Shelf_and_Bookcase.png	Wall mounted storage with racks	2026-04-03 08:06:13.258115
104	26	img/Products/Left_Corner_Plant.png	Big corner plants\r\nunits: 2	2026-04-03 08:06:40.392859
105	26	img/Products/Office_Chairs.png	black comfortable premium chairs\r\nunits: 2	2026-04-03 08:07:36.301373
106	26	img/Products/Desk_Pen_Holder_Plant.png	mini plants\r\nunits: 4	2026-04-03 08:08:32.753992
107	26	img/Products/Spherical_Desk_Lamp.png	table rounded lamp\r\nunits: 2	2026-04-03 08:08:56.918399
108	26	img/Products/Area_Rug.png	floor carpet\r\nsize: 10x8ft	2026-04-03 08:09:47.833311
109	26	img/Products/Office_Wall_Surfaces.png	wall colour: dark grey	2026-04-03 08:13:15.933355
110	22	img/Products/22_1.jpg	soft blue wall paint	2026-04-03 08:20:03.232774
111	21	img/Products/Solid_Wood_Desk.png	4x2ft 29inch strong double wooden table\r\nMaterial: 701 grade plywood	2026-04-03 22:30:29.738916
112	21	img/Products/Ergonomic_Chair.png	ergonomic ash coloured chair with headrest	2026-04-03 22:30:58.622403
113	21	img/Products/Potted_Plant.png	table plant	2026-04-03 22:31:12.889922
114	21	img/Products/Utensil_Holder.png	pen holder	2026-04-03 22:31:23.460838
70	29	img/Products/Screenshot_2026-04-04_at_6.01.43_PM.png	Wall Wooden Rack with 3xframes	2026-04-02 22:05:22.996036
115	17	img/Products/Framed_Art_Group.png	Frames\r\nSizes\r\n1. 10x12\r\n2. 6x8	2026-04-04 12:54:53.028489
116	17	img/Products/Minimalist_Figurines_and_Clock.png	Show Artefacts\r\n1. Astronauts(x3)\r\n2. Clock\r\n3. Daimond shaped artefact	2026-04-04 12:56:35.600174
117	17	img/Products/Area_Rug.png	Ash coloured carpet\r\nsize: 4x4ft	2026-04-04 12:59:27.128046
118	30	img/Products/30/30_sub1.jpg	Table: semi wood with black iron legs\r\nsize: 4x2ft 29' inch height	2026-04-04 16:44:25.267882
119	30	img/Products/30/30_sub2.jpg	Ergonomic chair\r\ncolour: ash	2026-04-04 16:44:25.267882
120	30	img/Products/30/30_sub3.jpg	plant	2026-04-04 16:44:25.267882
121	30	img/Products/30/30_sub4.jpg	pen holder\r\nsize: 6x3inch's	2026-04-04 16:44:25.267882
122	7	img/Products/lg.jpg	LG Monitor\r\nLG 24U411A 60.4 cm (23.8 Inch) Full HD (1920x1080) IPS Monitor, 120Hz, 5ms (GtG),VGA, HDMI, 3-Side Virtually Borderless Design, HDR 10, 1ms MBR, Reader Mode, Flicker Safe (2026)	2026-04-07 06:26:52.609656
123	22	img/Products/mixboard-image.png	Ergonomic Headrest Chair\r\ncolour: white with ash	2026-04-11 01:34:41.639868
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.products (id, name, description, category, price, rating, image_url, created_by, detailed_description, deal_percent) FROM stdin;
10	Bright space	S-204	Executive	42000	5.0	img/Products/IMG_9230.JPG	sri@gmail.com	\N	0
7	Base Green + monitor	S-201	Executive	56000	5.0	img/Products/IMG_20260407_115816.jpg	sri@gmail.com	Nature	0
17	Elegant Corner (Get What You See)	L-601	Executive	60000.0	5.0	img/Products/ChatGPT_Image_Apr_4_2026_06_15_42_PM-Photoroom.png	srichityala501@gmail.com	\N	0
21	Wood Magic (Get What You See)	M-103	Executive	20000.0	4.0	img/Products/basic3.png	srichityala501@gmail.com	\N	0
23	Green Asset (Get What You See)	G-501	Executive	60000.0	5.0	img/Products/G-602.png	srichityala501@gmail.com	\N	0
24	Dual Minds (Get What You See)	C-401	Executive	68000.0	5.0	img/Products/C-401.png	srichityala501@gmail.com	\N	0
25	Individual Space (Get What You See)	C-402	Executive	60000.0	5.0	img/Products/C-402.png	srichityala501@gmail.com	\N	0
26	Dark Magic (Get What You See)	L-601	Executive	90000.0	5.0	img/Products/26/26.jpg	srichityala501@gmail.com	\N	0
27	Rafter Studio Setup (Get What You See)	S-701	Executive	150000.0	5.0	img/Products/27/27.jpg	srichityala501@gmail.com	\N	0
29	Beige Minds (Get What You See)	S-206	Ergonomic	38000.0	5.0	img/Products/storage-Photoroom.png	srichityala501@gmail.com	\N	0
28	Scandi Minimal (Get What You See)	M-102	Minimalist	30000.0	5.0	img/Products/basic1.png	srichityala501@gmail.com	\N	0
22	Soft Sky (Get What You See)	E-303	Executive	48000.0	5.0	img/Products/ChatGPT_Image_Apr_11_2026_07_02_03_AM.png	srichityala501@gmail.com	\N	0
30	Semi Wood (Get What You See)	M-101	Minimalist	1000	5.0	img/Products/30/30.jpg	srichityala501@gmail.com	\N	0
\.


--
-- Data for Name: referral_coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.referral_coupons (id, user_id, coupon_code, discount_percentage, referral_bonus_percentage, times_used, total_referral_earnings, is_active, created_at, expires_at, discount_type, discount_amount, referrer_bonus_type, referrer_bonus_amount, min_order_amount, max_discount_amount, first_order_only, usage_limit, per_user_limit, description) FROM stdin;
1	9	SRI9	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
2	10	SYEDAH10	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
3	11	SYED11	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
4	15	SREEKA15	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
5	16	YAMINI16	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
6	17	VIJAYK17	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
7	12	HOME12	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
8	18	SREEKA18	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
9	19	TRICKS19	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
10	20	VIJAYK20	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
11	21	PARASC21	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
13	23	RQNYMM23	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
14	24	URLESP24	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
15	25	TZLYYN25	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
16	26	VGVYSV26	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
17	27	VISHNU27	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
19	13	SRICH13	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
20	28	YTTJKU28	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
21	29	EOVSRP29	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
18	14	CHITYA14	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 00:00:00	fixed	500.00	fixed	499.97	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
64	30	SRI50130	10.00	10.00	0	0.00	t	2026-04-18 11:37:41.683389	2027-04-18 00:00:00	fixed	500.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
65	31	SRI131	10.00	10.00	0	0.00	t	2026-04-18 11:37:41.683389	2027-04-18 00:00:00	fixed	499.99	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
66	32	GSPACE32	10.00	10.00	0	0.00	t	2026-04-18 11:37:41.683389	2027-04-18 00:00:00	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
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

COPY public.users (id, name, email, password, address, phone, profile_photo, address_line_2, city, state, pincode, country, landmark, alternate_phone, company_name, gstin, wallet_balance, wallet_bonus_limit, referral_code, referred_by_user_id, signup_bonus_credited, first_order_completed) FROM stdin;
9	sri	sri@gmail.com	sri	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SRI9	\N	t	f
10	Syed Ahmed	syed.ahmed8801302@gmail.com	aTNkZUoq	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SYEDAH10	\N	t	f
11	syed	syed@gmail.com	syed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SYED11	\N	t	f
15	Sreekanth Devops	sreekanththetechie@gmail.com	oauth_user_no_password_6lUorcIT7qfGlC3V	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SREEKA15	\N	t	f
16	yamini chityala	chityalayamini@gmail.com	oauth_user_no_password_d69XXaVVlKg5aIG2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	YAMINI16	\N	t	f
17	Vijay Kumar	sri.vijaychittiyala@gmail.com	D@rk#0rse	\N	7416542354	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK17	\N	t	f
12	Home	sri.chityala504@gmail.com		\N	7075077384	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	HOME12	\N	t	f
18	sreekanth chityala	sri.chityala502@gmail.com	oauth_user_no_password_ngSnkOCN8GJhg6vh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SREEKA18	\N	t	f
19	Tricks And Techniques	tricksntechniques@gmail.com	oauth_user_no_password_LHzOq6UXdVbS9vqa	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	TRICKS19	\N	t	f
20	vijay kumar chityala	sri.vijaychityala@gmail.com	oauth_user_no_password_P6gvG8zHXcjvzhuh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK20	\N	t	f
21	paras chandel	ra5161575@gmail.com	Paras@98	\N	9354634458	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	PARASC21	\N	t	f
23	rqnymmdgxh	mjrudusn@checkyourform.xyz	ynekqnxrzzzs	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	RQNYMM23	\N	t	f
24	urlesprorl	gmhjtnox@checkyourform.xyz	xlyohuxehqkv	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	URLESP24	\N	t	f
25	tzlyynopyq	wgiwlupo@checkyourform.xyz	prqrikhlvfwp	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	TZLYYN25	\N	t	f
26	vgvysvgvdw	yggkgmzz@immenseignite.info	kqvwzvqodyds	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VGVYSV26	\N	t	f
27	Vishnu Chityala	vishnurchityala@gmail.com	oauth_user_no_password_iaPILT6luNGdt4Ln	\N	9537234000	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VISHNU27	\N	t	f
14	chityala srikanth	srichityala501@gmail.com		Hyderabad	7075077384	img/profiles/user_14_1775881216.png		Hyderabad	Telangana	500051	India					500.00	10000.00	CHITYA14	\N	t	f
13	Sri ch	sri.chityala500@gmail.com	hello	hyd	7075077384	img/profiles/user_13_1775884609.png		hyd	telangana	500051	India					500.00	10000.00	SRICH13	\N	t	f
28	yttjkusnft	oswfshdi@immenseignite.info	oosvyqzqugrt	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	YTTJKU28	\N	t	f
29	eovsrpvtpd	lwludtyo@ immenseignite.info	dmirjiotgvks	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	EOVSRP29	\N	t	f
30	sri501	sri501@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	10000.00	SRI50130	\N	f	f
31	sri1	sri1@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SRI131	\N	t	f
32	gspaces	gspaces2025@gmail.com	oauth_user_no_password_KthRRpoNZQ62vltK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	GSPACE32	\N	t	f
\.


--
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, reference_type, reference_id, created_at, metadata) FROM stdin;
1	9	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
2	10	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
3	11	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
4	15	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
5	16	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
6	17	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
7	12	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
8	18	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
9	19	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
10	20	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
11	21	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
13	23	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
14	24	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
15	25	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
16	26	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
17	27	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
18	14	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
19	13	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
20	28	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
21	29	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
22	31	bonus	500.00	500.00	Welcome bonus for sri1	signup	\N	2026-04-17 19:55:58.75635	{"bonus_type": "signup"}
23	32	bonus	500.00	500.00	Welcome bonus for gspaces	signup	\N	2026-04-18 11:17:34.318248	{"bonus_type": "signup"}
28	32	admin_credit	100.00	600.00	Admin adjustment by srichityala501@gmail.com	\N	\N	2026-04-18 14:19:34.397815	\N
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.wallets (id, user_id, balance, created_at, updated_at) FROM stdin;
22	30	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:56:36.370172
24	32	600.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
1	9	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
2	10	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
3	11	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
4	15	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
5	16	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
6	17	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
7	12	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
8	18	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
9	19	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
10	20	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
11	21	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
13	23	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
14	24	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
15	25	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
16	26	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
17	27	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
18	14	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
19	13	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
20	28	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
21	29	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
23	31	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
\.


--
-- Name: cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.cart_id_seq', 97, true);


--
-- Name: coupon_usage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupon_usage_id_seq', 1, false);


--
-- Name: coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupons_id_seq', 7, true);


--
-- Name: discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.discount_id_seq', 58, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.order_items_id_seq', 48, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.orders_id_seq', 57, true);


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.otp_verifications_id_seq', 2, true);


--
-- Name: product_sub_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_sub_images_id_seq', 123, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.products_id_seq', 30, true);


--
-- Name: referral_coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.referral_coupons_id_seq', 66, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.reviews_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.users_id_seq', 32, true);


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.wallet_transactions_id_seq', 28, true);


--
-- Name: wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.wallets_id_seq', 28, true);


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
-- Name: coupon_usage coupon_usage_coupon_id_order_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_order_id_key UNIQUE (coupon_id, order_id);


--
-- Name: coupon_usage coupon_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_code_key UNIQUE (code);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (id);


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
-- Name: otp_verifications otp_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.otp_verifications
    ADD CONSTRAINT otp_verifications_pkey PRIMARY KEY (id);


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
-- Name: referral_coupons referral_coupons_coupon_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_coupon_code_key UNIQUE (coupon_code);


--
-- Name: referral_coupons referral_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: referral_coupons unique_user_referral; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT unique_user_referral UNIQUE (user_id);


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
-- Name: users users_referral_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referral_code_key UNIQUE (referral_code);


--
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_key UNIQUE (user_id);


--
-- Name: idx_coupon_usage_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupon_usage_user_id ON public.coupon_usage USING btree (user_id);


--
-- Name: idx_coupons_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupons_user_id ON public.coupons USING btree (user_id);


--
-- Name: idx_otp_email; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_email ON public.otp_verifications USING btree (email);


--
-- Name: idx_otp_expires; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_expires ON public.otp_verifications USING btree (expires_at);


--
-- Name: idx_referral_coupons_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_active ON public.referral_coupons USING btree (is_active);


--
-- Name: idx_referral_coupons_code; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_code ON public.referral_coupons USING btree (coupon_code);


--
-- Name: idx_referral_coupons_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_user_id ON public.referral_coupons USING btree (user_id);


--
-- Name: idx_users_referral_code; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_users_referral_code ON public.users USING btree (referral_code);


--
-- Name: idx_wallet_transactions_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallet_transactions_created_at ON public.wallet_transactions USING btree (created_at DESC);


--
-- Name: idx_wallet_transactions_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallet_transactions_user_id ON public.wallet_transactions USING btree (user_id);


--
-- Name: idx_wallets_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallets_user_id ON public.wallets USING btree (user_id);


--
-- Name: users trigger_auto_referral_code; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER trigger_auto_referral_code BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.auto_generate_referral_code();


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
-- Name: coupon_usage coupon_usage_coupon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_fkey FOREIGN KEY (coupon_id) REFERENCES public.coupons(id) ON DELETE CASCADE;


--
-- Name: coupon_usage coupon_usage_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: coupon_usage coupon_usage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: coupons coupons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


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
-- Name: referral_coupons referral_coupons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


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
-- Name: users users_referred_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_user_id_fkey FOREIGN KEY (referred_by_user_id) REFERENCES public.users(id);


--
-- Name: wallet_transactions wallet_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

