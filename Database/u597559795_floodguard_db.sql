-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Nov 13, 2026 at 03:04 AM
-- Server version: 11.8.9-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u597559795_floodguard_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`id`, `full_name`, `email`, `password`, `status`, `last_login_at`, `created_at`, `updated_at`) VALUES
(2, 'FloodGuard Administrator', 'admin@floodguard.com', '$2y$10$ggQU7LLB6bVYB90GtFF45uq/0GghrslSWtzp//meBjWnHXDGE4ywK', 'active', '2026-10-01 15:53:45', '2026-08-01 02:58:50', '2026-10-01 07:53:45');

-- --------------------------------------------------------

--
-- Table structure for table `alert_logs`
--

CREATE TABLE `alert_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sensor_reading_id` bigint(20) UNSIGNED DEFAULT NULL,
  `alert_level` enum('normal','warning','critical') NOT NULL,
  `alert_scope` enum('community','bridge','all') NOT NULL,
  `alert_title` varchar(150) NOT NULL,
  `alert_message` text NOT NULL,
  `alert_source` enum('automatic','manual') NOT NULL DEFAULT 'automatic',
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `api_tokens`
--

CREATE TABLE `api_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_name` varchar(100) NOT NULL,
  `token_hash` char(64) NOT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `api_tokens`
--

INSERT INTO `api_tokens` (`id`, `user_id`, `token_name`, `token_hash`, `last_used_at`, `expires_at`, `revoked_at`, `created_at`) VALUES
(1, 2, 'resident-mobile', '79ffdbb0c8fbd151b304888acdcff4a5ea392ed77c329dbe5e9546ae6bdb5953', '2026-09-08 12:54:34', '2026-10-08 12:46:54', '2026-09-08 12:58:21', '2026-09-08 04:46:54'),
(2, 5, 'responder-mobile', 'c017e80832a448b22224946da6e235ab05950b561e43531ece3d3bd6bbf3e8d1', '2026-09-09 09:33:11', '2026-10-09 09:23:03', '2026-09-09 09:39:42', '2026-09-09 01:23:03'),
(3, 2, 'resident-mobile', '4273c8c5c7d3aabb7280c87fc8e7fcf4e43ba66b40413c0f5f40f9edf3eb0d8c', '2026-09-20 10:49:26', '2026-10-20 10:44:41', NULL, '2026-09-20 02:44:41'),
(4, 2, 'resident-mobile', '971dbec09705f81c31128ef9bd17fe5e6380ef8eb624c0883b6ad71ff655bb71', NULL, '2026-10-20 15:17:04', NULL, '2026-09-20 07:17:04'),
(5, 2, 'resident-mobile', 'd8707e5fca28444e7cd4d31c63579a6ba2b03b4f5d5e140a28cdc7c97edeac82', NULL, '2026-10-20 15:18:01', '2026-09-20 15:18:05', '2026-09-20 07:18:01'),
(6, 5, 'responder-mobile', 'd055d87f9442811d65391473e967a8c7b6b45ce63258ab41a87dd4153b093d82', NULL, '2026-10-20 15:18:57', '2026-09-20 15:19:09', '2026-09-20 07:18:57'),
(7, 2, 'resident-mobile', '670cde9d49647122098b2c00ab62abe2db36c498805775d089a8865cee3139ae', '2026-09-20 15:40:02', '2026-10-20 15:39:53', NULL, '2026-09-20 07:39:53'),
(8, 2, 'resident-mobile', '97904be0c06fd68a06a04453c2d376f3fb4430ddf89595bf3a55446c30a6eea7', '2026-09-20 15:50:40', '2026-10-20 15:40:21', NULL, '2026-09-20 07:40:21'),
(9, 5, 'responder-mobile', 'dfa2c48f46dd889645ee9a2e851c338d7857dbb9c4582cc49bf5373e9dcff4ca', '2026-09-20 16:29:27', '2026-10-20 16:20:52', NULL, '2026-09-20 08:20:52'),
(10, 5, 'responder-mobile', '9147d5231e8aa8b5f42ffe347056b3a5f2c61c943efee89b9a468508eef82e24', '2026-09-20 16:43:01', '2026-10-20 16:34:26', NULL, '2026-09-20 08:34:26'),
(11, 2, 'resident-mobile', 'fbb0c5e877de2376370319fed03f3bbc84042fe0ea0032f1dfba13ebea55a543', '2026-09-20 22:32:12', '2026-10-20 22:32:11', NULL, '2026-09-20 14:32:11'),
(12, 2, 'resident-mobile', 'be970183cdfcb6a386b77963185028af7e8914fddd0d69aa9d445d3b27086ef9', '2026-09-20 22:41:37', '2026-10-20 22:39:24', '2026-09-20 22:44:23', '2026-09-20 14:39:24'),
(13, 5, 'responder-mobile', 'e0d79877e561c0aa8c6723b67fadfe6db53cada8ef250657d63ae70cd23877d8', '2026-09-20 22:45:01', '2026-10-20 22:44:36', NULL, '2026-09-20 14:44:36'),
(14, 5, 'responder-mobile', 'bf3037c00899714d7dcedbd252b35681d2badf93258b25cfc7b457f488a9cb9b', '2026-09-20 22:51:43', '2026-10-20 22:50:04', '2026-09-20 22:51:47', '2026-09-20 14:50:04'),
(15, 2, 'resident-mobile', 'd723b5fc48dd18cd8df9b3d6b786908cad37916b9b3d34ed0f9a9ef8b6393927', '2026-09-20 22:53:41', '2026-10-20 22:52:00', NULL, '2026-09-20 14:52:00'),
(16, 2, 'resident-mobile', '88e7c888b6de99bb27c91e33a404d0e10dcb39dc4059662bb8d2ddc26d3faafb', '2026-09-20 23:09:02', '2026-10-20 22:57:57', NULL, '2026-09-20 14:57:57'),
(17, 2, 'resident-mobile', 'd55e6ccb603cdf21706c9ed167cd32994ab7acf6344354be1ba2397611448f5e', '2026-09-20 23:23:26', '2026-10-20 23:22:08', NULL, '2026-09-20 15:22:08'),
(18, 2, 'resident-mobile', '73fe620d68bd8d2770d9550798c59f83bd344dfb9377399af4d6088dfabc1a5d', '2026-09-21 16:46:09', '2026-10-21 16:45:19', NULL, '2026-09-21 08:45:19'),
(19, 5, 'responder-mobile', '46e1883eebde9a1f837278e813a902cb186e728c650fb14199b8f81107c17a46', '2026-09-21 16:56:08', '2026-10-21 16:55:15', NULL, '2026-09-21 08:55:15'),
(20, 5, 'responder-mobile', '50bfdf1f53108f986dab404df6b4baf3a4c2cb632bbff6fcdf68cf33a51853df', '2026-09-21 17:01:36', '2026-10-21 17:01:13', NULL, '2026-09-21 09:01:13'),
(22, 5, 'responder-mobile', '9fb90e3505a588de658dfd713cad31ca44a205f25e569fcc494e1364ce480414', '2026-09-23 15:21:02', '2026-10-23 15:20:17', NULL, '2026-09-23 07:20:17'),
(23, 2, 'resident-mobile', 'e338a08f84e320eb3e756099bbc7852d9c17d52f1daf9f02f5e711a149be00e1', '2026-09-23 15:21:37', '2026-10-23 15:21:13', '2026-09-23 15:21:41', '2026-09-23 07:21:13'),
(24, 5, 'responder-mobile', '34bd6f28c35bbd849987304849f91d4a382a3b773803bc95bc8335564aa7f257', '2026-09-23 15:22:45', '2026-10-23 15:21:53', NULL, '2026-09-23 07:21:53'),
(25, 2, 'resident-mobile', 'ab3c2346df6853c814f9d6756b767cbe0583112c8a0f308c58b69bc3f80f5443', '2026-09-24 15:11:31', '2026-10-24 15:10:57', '2026-09-24 15:11:36', '2026-09-24 07:10:57'),
(26, 5, 'responder-mobile', 'f91dc7b77290c0fa3b2d085e558b8c6b96cb25dae4cbbf4e6ec7b47d6c824bf4', '2026-09-24 15:11:49', '2026-10-24 15:11:45', NULL, '2026-09-24 07:11:45'),
(27, 2, 'resident-mobile', 'bf36af072cb8917cb6fcf59fdd30c4966109734bde4cc324e59620633adb0179', '2026-09-24 15:14:12', '2026-10-24 15:13:33', NULL, '2026-09-24 07:13:33'),
(28, 7, 'resident-mobile', '0f42088f1a97c822a14580f5e2c295d1acb70f5c9ca2ed24c8237bef7066a384', '2026-09-25 12:21:42', '2026-10-25 12:21:26', '2026-09-25 12:25:39', '2026-09-25 04:21:26'),
(29, 7, 'resident-mobile', 'ef3edbffbe4d48595dff2674076f89794932af0145cca79ba2a09b84bacd0923', '2026-09-25 12:59:11', '2026-10-25 12:58:58', '2026-09-25 13:14:31', '2026-09-25 04:58:58'),
(30, 7, 'resident-mobile', 'e26197a05c4ce684910d2f4ae1e9d9f63986ca03f87534bce7b86e7b4ae939f9', '2026-09-25 12:59:50', '2026-10-25 12:59:49', '2026-09-25 13:14:31', '2026-09-25 04:59:49'),
(31, 7, 'resident-mobile', '5d6ca5173581078eeb25073bc0066685664869083059a35327e164eab7c68f3a', '2026-09-25 13:12:17', '2026-10-25 13:12:00', '2026-09-25 13:12:25', '2026-09-25 05:12:00'),
(32, 7, 'resident-mobile', '9d70443b49d2795f739360a9e1f09543bcf6606dfeeb1469297189116a70d58a', '2026-09-25 15:55:42', '2026-10-25 15:55:33', NULL, '2026-09-25 07:55:33'),
(33, 7, 'resident-mobile', 'c2935181804c141a36ffc9f1eee8d4e1faa77f9e412f92e30f31901a01cde13a', '2026-09-25 17:29:29', '2026-10-25 17:26:29', '2026-09-25 17:29:35', '2026-09-25 09:26:29'),
(34, 5, 'responder-mobile', 'd3dc1eb184cbbfcb99a20fb18be3f186776dbb4818cfe82baaa0455aa0e32cd0', '2026-09-25 17:31:40', '2026-10-25 17:30:39', NULL, '2026-09-25 09:30:39'),
(35, 7, 'resident-mobile', '149103e1bdaf3dad2adc520322c552cfe8dfe9bd4f154825c7bada8c4bea4959', '2026-09-25 10:57:06', '2026-10-25 18:57:00', NULL, '2026-09-25 10:57:00'),
(36, 7, 'resident-mobile', 'f10240864b8e7f3091629579b02f249edb1b9cf43aab38431e9e19f9d1f4d7d2', '2026-09-25 11:09:38', '2026-10-25 19:04:41', '2026-09-25 11:09:44', '2026-09-25 11:04:41'),
(37, 7, 'resident-mobile', '0feb9c6ec5c20d46f5eb184936bb5b0a40ac123c5fb9eee86dd26b0530e2ec93', '2026-09-26 08:34:11', '2026-10-26 16:34:06', '2026-09-26 08:34:18', '2026-09-26 08:34:06'),
(38, 7, 'resident-mobile', '3470a8c2fac6ae97cd54f489df9e954750acc9a5cef9fa23a49168ed9f54aa57', '2026-09-26 08:36:17', '2026-10-26 16:34:44', '2026-09-26 08:36:47', '2026-09-26 08:34:44'),
(39, 5, 'responder-mobile', '8f6a7181e29228e559e522866ac230b99087578962646637c088829263138f1b', '2026-09-26 08:36:41', '2026-10-26 16:35:18', '2026-09-26 08:36:46', '2026-09-26 08:35:18'),
(40, 7, 'resident-mobile', 'a1472752985c306ee36d811968d036d8e28190d81b978182a2f670d372555174', '2026-09-26 09:09:57', '2026-10-26 16:37:23', NULL, '2026-09-26 08:37:23'),
(41, 5, 'responder-mobile', 'f7bc7f011c2a105cd108ac62f53064c10deebea2c7472e04f36d1ce9d5e6216e', '2026-09-26 08:37:56', '2026-10-26 16:37:25', NULL, '2026-09-26 08:37:25'),
(42, 5, 'responder-mobile', 'b1c6aa786a6fda0518e2bc4219ab84a91b317124f41be33637039953e8990d9b', '2026-09-26 08:51:34', '2026-10-26 16:40:14', NULL, '2026-09-26 08:40:14'),
(43, 5, 'responder-mobile', '5f65359270573ccf967d9c31670145e9062274925c2a9d4fe143f896aac415fc', '2026-09-26 08:51:58', '2026-10-26 16:51:54', NULL, '2026-09-26 08:51:54'),
(44, 5, 'responder-mobile', 'fc738c219bea2ad52b2a7b172cc13c1b6e516c2c1821ee9d378488043c5aab03', '2026-09-26 09:02:23', '2026-10-26 16:55:33', NULL, '2026-09-26 08:55:33'),
(45, 5, 'responder-mobile', '9f3afa4897f2050b3c2fcf338a01d607bca4d92df767c8f347a382e1363b44fe', '2026-09-26 09:10:40', '2026-10-26 17:05:15', '2026-09-26 09:10:42', '2026-09-26 09:05:15'),
(46, 7, 'resident-mobile', '7bb72ab9d0e29ff93dde8da4269abb7919c39b4f1ef8cbb15ba8a26fd46a5d81', '2026-09-26 09:13:39', '2026-10-26 17:10:56', NULL, '2026-09-26 09:10:56'),
(47, 2, 'resident-mobile', '4111feb5c0acb48f7d01f36d430a08317ee3562876cbba8c2cf615112a1ac174', '2026-09-28 14:22:43', '2026-10-28 14:21:35', NULL, '2026-09-28 06:21:35'),
(48, 2, 'resident-mobile', 'c862f12791b4964fd5fa29fb54971ef742e612c40052e1baaf33146bd63e19cb', '2026-09-28 14:44:43', '2026-10-28 14:44:36', '2026-09-28 14:45:04', '2026-09-28 06:44:36'),
(49, 7, 'resident-mobile', '0933099947ef132e1a77836a0ab024688a4e2eed45e8cc4a8a2d34c1c6e8905b', '2026-09-28 15:20:18', '2026-10-28 14:45:28', NULL, '2026-09-28 06:45:28'),
(50, 7, 'resident-mobile', '990244fb229a35cd9fb47465410d9eee473374aef00bd9dde7ec48aaffe21ad4', '2026-09-28 15:24:49', '2026-10-28 15:20:58', '2026-09-28 15:24:58', '2026-09-28 07:20:58'),
(51, 7, 'resident-mobile', 'f6d0d638fec6abfe728d162584527371e31b6a8096b20a9c0e98ca04f889bcd3', '2026-09-28 15:37:17', '2026-10-28 15:25:20', NULL, '2026-09-28 07:25:20'),
(52, 7, 'resident-mobile', 'fe0a3d0add0316d183f5f55827a97b8cb7c430f01d7d79fd8f16171952526edf', '2026-09-28 15:46:25', '2026-10-28 15:45:56', NULL, '2026-09-28 07:45:56'),
(53, 7, 'resident-mobile', 'b389f74d944533f361b5c34156e54f19d0f355d72461132e65d09078d953af73', '2026-09-28 22:35:51', '2026-10-28 16:40:55', NULL, '2026-09-28 08:40:55'),
(54, 7, 'resident-mobile', '51faff5eca718ebb24694b30fdb993315c7b26fb1b667cd5daa47c6d784b711e', '2026-09-29 17:09:17', '2026-10-28 22:41:45', '2026-09-29 17:09:17', '2026-09-28 14:41:45'),
(55, 5, 'responder-mobile', '0748c67db022f4e85416edcfa98813449231a7bea2700384531958b81c55a1c6', '2026-10-01 02:49:42', '2026-10-29 17:09:42', '2026-10-01 02:49:45', '2026-09-29 09:09:42'),
(56, 7, 'resident-mobile', '79ad57c547fe54f2de1a4a8d8cc2fb0c114d184e91fa63d4eda54c0058c5aa64', '2026-09-30 15:41:48', '2026-10-30 15:24:43', '2026-09-30 15:41:49', '2026-09-30 07:24:43'),
(57, 7, 'resident-mobile', '69db2187c41a081b64e46bb3b1e90ed1bbd00f46aca9b5b50f5add1f82576df4', '2026-09-30 20:20:42', '2026-10-30 15:46:20', NULL, '2026-09-30 07:46:20'),
(58, 7, 'resident-mobile', 'c9e2db3fa8cbea327f31a4ac7c187fb9f53e8041e563c59cf064aefde810f887', '2026-09-30 23:42:04', '2026-10-30 20:04:34', '2026-09-30 23:42:05', '2026-09-30 12:04:34'),
(59, 7, 'resident-mobile', '9c393a479b656a4a22e6d27d47c71fa5265b4998ee2f86177be41f685e8b3d21', '2026-10-01 02:21:58', '2026-10-30 23:52:45', '2026-10-01 02:21:58', '2026-09-30 15:52:45'),
(60, 7, 'resident-mobile', '410d108ed472062d48d214f3a259b2ef9026134d9b898cfb5269c722c50a42f7', '2026-10-01 10:38:57', '2026-10-31 02:50:07', '2026-10-01 10:38:57', '2026-09-30 18:50:07'),
(61, 7, 'resident-mobile', '99a6a6fd90a1e95f6307be65c31fc61a63ed49197660ff9f2f9b634564aaa777', '2026-10-01 10:39:16', '2026-10-31 10:38:50', '2026-10-01 10:39:16', '2026-10-01 02:38:50'),
(62, 11, 'responder-mobile', '26f71e5532b905016c861c3ed6a36b3208769f5ac7d5e11ed32db815bcd2e4bc', '2026-10-01 11:26:58', '2026-10-31 10:39:24', '2026-10-01 11:27:00', '2026-10-01 02:39:24'),
(63, 12, 'resident-mobile', '477381a72195dc25d7fe879135631e4d8d2ba0149e4d56160b759a045c295de1', '2026-10-01 11:23:27', '2026-10-31 10:46:25', NULL, '2026-10-01 02:46:25'),
(64, 11, 'responder-mobile', '49da97124c9a68955d380228447f1605f3429b6bb737488f58da4486fbdd3f19', '2026-10-01 11:35:20', '2026-10-31 11:27:21', NULL, '2026-10-01 03:27:21'),
(65, 11, 'responder-mobile', '7eb6f687f5afe1aacb6ef91881a348cd57be3fd9838b1446ca972a30d516eede', '2026-10-01 17:13:57', '2026-10-31 11:45:24', NULL, '2026-10-01 03:45:24'),
(66, 7, 'resident-mobile', '221a3c6b7b7fcc5fa1ff8e00c99ef1c79811c58fcf9352318e0a662b6cccd199', '2026-10-01 16:26:20', '2026-10-31 16:25:43', '2026-10-01 16:26:21', '2026-10-01 08:25:43'),
(67, 13, 'resident-mobile', '414573a63030bb3290986eea63ec1adeb9f4c18f1570b75f90a5634162e81994', '2026-10-01 17:12:13', '2026-10-31 16:55:11', '2026-10-01 17:12:13', '2026-10-01 08:55:11'),
(68, 13, 'resident-mobile', '1887353cc9cb41d1d028725415d23cf125abdd8ecb3d29d8e503fd1ddb00904c', '2026-10-13 01:08:11', '2026-10-31 17:13:38', NULL, '2026-10-01 09:13:38');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actor_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(80) NOT NULL,
  `entity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `before_json` longtext DEFAULT NULL,
  `after_json` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `ip_address`, `user_agent`, `before_json`, `after_json`, `created_at`) VALUES
(1, 2, 'flood_report.created', 'flood_report', 1, '::1', 'curl/8.21.0', NULL, '{\"report_number\":\"FG-RPT-20260908-C55BBD71\",\"status\":\"submitted\",\"immediate_danger\":false}', '2026-09-08 04:52:41'),
(2, 3, 'flood_report.under_review', 'flood_report', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"under_review\",\"reason\":null}', '2026-09-08 05:23:30'),
(3, 3, 'incident.created', 'flood_incident', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260908-BCC05278\",\"priority\":\"medium\",\"public_approved\":true}', '2026-09-08 05:25:50'),
(4, 3, 'flood_report.approved', 'flood_report', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', '{\"status\":\"under_review\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-08 05:25:50'),
(5, 3, 'response_team.created', 'response_team', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', NULL, '{\"team_name\":\"Team A\"}', '2026-09-09 00:51:30'),
(6, 3, 'response_team.member_added', 'response_team', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', NULL, '{\"responder_user_id\":5}', '2026-09-09 00:51:50'),
(7, 3, 'assignment.created', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', NULL, '{\"incident_id\":1,\"team_id\":1}', '2026-09-09 01:22:05'),
(8, 5, 'assignment.accepted', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-PH) WindowsPowerShell/5.1.26100.9168', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-09 01:27:45'),
(9, 5, 'assignment.en_route', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-PH) WindowsPowerShell/5.1.26100.9168', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":\"Responder team is traveling to the reported location.\"}', '2026-09-09 01:29:29'),
(10, 5, 'assignment.on_scene', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-PH) WindowsPowerShell/5.1.26100.9168', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":\"Responder team has arrived at the reported location.\"}', '2026-09-09 01:31:09'),
(11, 5, 'assignment.response_in_progress', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-PH) WindowsPowerShell/5.1.26100.9168', '{\"status\":\"on_scene\"}', '{\"status\":\"response_in_progress\",\"notes\":\"Responder team is assessing the area and assisting affected residents.\"}', '2026-09-09 01:31:51'),
(12, 5, 'assignment.completed', 'incident_assignment', 1, '::1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-PH) WindowsPowerShell/5.1.26100.9168', '{\"status\":\"response_in_progress\"}', '{\"status\":\"completed\",\"notes\":\"Controlled test completed. The area was assessed and no real emergency occurred.\"}', '2026-09-09 01:33:11'),
(13, 2, 'flood_report.created', 'flood_report', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20260920-EEF82D07\",\"status\":\"submitted\",\"immediate_danger\":false}', '2026-09-20 07:45:57'),
(14, 3, 'flood_report.under_review', 'flood_report', 2, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"under_review\",\"reason\":null}', '2026-09-20 07:49:51'),
(15, 3, 'incident.created', 'flood_incident', 2, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260920-8A353242\",\"priority\":\"medium\",\"public_approved\":false}', '2026-09-20 07:50:29'),
(16, 3, 'flood_report.approved', 'flood_report', 2, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"under_review\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-20 07:50:29'),
(17, 3, 'assignment.created', 'incident_assignment', 2, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_id\":2,\"team_id\":1}', '2026-09-20 08:19:31'),
(18, 5, 'assignment.accepted', 'incident_assignment', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-20 08:22:24'),
(19, 5, 'assignment.en_route', 'incident_assignment', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":null}', '2026-09-20 08:24:56'),
(20, 5, 'assignment.on_scene', 'incident_assignment', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":null}', '2026-09-20 08:27:11'),
(21, 5, 'assignment.response_in_progress', 'incident_assignment', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"on_scene\"}', '{\"status\":\"response_in_progress\",\"notes\":null}', '2026-09-20 08:28:02'),
(22, 5, 'assignment.completed', 'incident_assignment', 2, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"response_in_progress\"}', '{\"status\":\"completed\",\"notes\":\"Test response completed. Area inspected and the reported flood condition was verified. No immediate danger remains.\"}', '2026-09-20 08:29:26'),
(23, 2, 'flood_report.created', 'flood_report', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20260920-22BBB6AC\",\"status\":\"submitted\",\"immediate_danger\":false}', '2026-09-20 14:41:36'),
(24, 3, 'flood_report.under_review', 'flood_report', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"under_review\",\"reason\":null}', '2026-09-20 14:41:59'),
(25, 3, 'incident.created', 'flood_incident', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260920-0C700ED5\",\"priority\":\"medium\",\"public_approved\":false}', '2026-09-20 14:43:06'),
(26, 3, 'flood_report.approved', 'flood_report', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"under_review\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-20 14:43:06'),
(27, 3, 'assignment.created', 'incident_assignment', 3, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_id\":3,\"team_id\":1}', '2026-09-20 14:44:17'),
(28, 5, 'assignment.accepted', 'incident_assignment', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-20 14:44:55'),
(29, 2, 'community_post.created', 'community_post', 1, '127.0.0.1', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20260920-32BDF5D0\",\"status\":\"submitted\"}', '2026-09-20 15:23:25'),
(30, 3, 'community_post.under_review', 'community_post', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"under_review\",\"notes\":null}', '2026-09-20 15:30:41'),
(31, 3, 'community_post.published', 'community_post', 1, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"under_review\"}', '{\"status\":\"published\",\"notes\":null}', '2026-09-20 15:30:49'),
(32, 2, 'flood_report.created', 'flood_report', 4, '127.0.0.1', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20260921-84D8EB5F\",\"status\":\"submitted\",\"immediate_danger\":false}', '2026-09-21 08:46:08'),
(33, 3, 'incident.created', 'flood_incident', 4, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260921-78FDC9C9\",\"priority\":\"medium\"}', '2026-09-21 08:53:28'),
(34, 3, 'flood_report.approved', 'flood_report', 4, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-21 08:53:28'),
(35, 5, 'assignment.en_route', 'incident_assignment', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":null}', '2026-09-21 08:55:23'),
(36, 5, 'assignment.on_scene', 'incident_assignment', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":null}', '2026-09-21 08:55:29'),
(37, 5, 'assignment.response_in_progress', 'incident_assignment', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"on_scene\"}', '{\"status\":\"response_in_progress\",\"notes\":null}', '2026-09-21 08:55:32'),
(38, 5, 'assignment.completed', 'incident_assignment', 3, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"response_in_progress\"}', '{\"status\":\"completed\",\"notes\":\"all good\"}', '2026-09-21 09:01:28'),
(39, 3, 'assignment.created', 'incident_assignment', 4, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', NULL, '{\"incident_id\":4,\"team_id\":1}', '2026-09-23 07:19:36'),
(40, 5, 'assignment.accepted', 'incident_assignment', 4, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-23 07:20:38'),
(41, 5, 'assignment.en_route', 'incident_assignment', 4, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":null}', '2026-09-23 07:20:58'),
(42, 5, 'assignment.on_scene', 'incident_assignment', 4, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":null}', '2026-09-23 07:22:08'),
(43, 5, 'assignment.completed', 'incident_assignment', 4, '127.0.0.1', 'Dart/3.13 (dart:io)', '{\"status\":\"on_scene\"}', '{\"status\":\"completed\",\"notes\":\"ok\"}', '2026-09-23 07:22:38'),
(44, 1, 'resident_account.approve', 'user', 6, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"approved\",\"reason\":null}', '2026-09-24 08:58:48'),
(45, 1, 'resident_account.approve', 'user', 7, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"approved\",\"reason\":null}', '2026-09-25 04:19:15'),
(46, 1, 'resident_account.reject', 'user', 7, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"approved\",\"account_status\":\"active\"}', '{\"approval_status\":\"rejected\",\"reason\":\"not verified\"}', '2026-09-25 05:14:31'),
(47, 1, 'resident_account.reject', 'user', 9, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"rejected\",\"reason\":\"not resident\"}', '2026-09-25 05:29:09'),
(48, 1, 'resident_account.approve', 'user', 7, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"approved\",\"reason\":null}', '2026-09-25 07:55:05'),
(49, 7, 'community_post.created', 'community_post', 2, '138.84.142.129', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20260925-46449676\",\"status\":\"submitted\"}', '2026-09-25 11:05:48'),
(50, 3, 'community_post.published', 'community_post', 2, '138.84.142.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"published\",\"notes\":null}', '2026-09-25 11:07:32'),
(51, 7, 'flood_report.created', 'flood_report', 5, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20260926-256335FB\",\"status\":\"submitted\",\"immediate_danger\":true}', '2026-09-26 08:35:39'),
(52, 3, 'incident.created', 'flood_incident', 5, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260926-6AB15B55\",\"priority\":\"medium\"}', '2026-09-26 08:36:17'),
(53, 3, 'flood_report.approved', 'flood_report', 5, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-26 08:36:17'),
(54, 3, 'assignment.created', 'incident_assignment', 5, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_id\":5,\"team_id\":1}', '2026-09-26 08:36:24'),
(55, 5, 'assignment.accepted', 'incident_assignment', 5, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-26 08:59:49'),
(56, 5, 'assignment.en_route', 'incident_assignment', 5, '175.158.204.123', 'Dart/3.13 (dart:io)', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":null}', '2026-09-26 09:05:44'),
(57, 5, 'assignment.on_scene', 'incident_assignment', 5, '175.158.204.123', 'Dart/3.13 (dart:io)', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":null}', '2026-09-26 09:10:02'),
(58, 5, 'assignment.completed', 'incident_assignment', 5, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"on_scene\"}', '{\"status\":\"completed\",\"notes\":\"Good\"}', '2026-09-26 09:10:12'),
(59, 7, 'community_post.created', 'community_post', 3, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20260926-59466795\",\"status\":\"submitted\"}', '2026-09-26 09:12:29'),
(60, 3, 'community_post.published', 'community_post', 3, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"published\",\"notes\":null}', '2026-09-26 09:13:08'),
(61, 7, 'community_post.deleted', 'community_post', 2, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"post_number\":\"FG-POST-20260925-46449676\",\"status\":\"published\"}', NULL, '2026-09-28 06:45:49'),
(62, 7, 'community_post.created', 'community_post', 4, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20260928-51F78E75\",\"status\":\"submitted\"}', '2026-09-28 06:47:11'),
(63, 3, 'community_post.published', 'community_post', 4, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"published\",\"notes\":null}', '2026-09-28 06:47:29'),
(64, 7, 'community_post.deleted', 'community_post', 4, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"post_number\":\"FG-POST-20260928-51F78E75\",\"status\":\"published\"}', NULL, '2026-09-28 06:48:23'),
(65, 7, 'flood_report.created', 'flood_report', 6, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20260930-54C8401B\",\"status\":\"submitted\",\"immediate_danger\":false}', '2026-09-30 08:40:57'),
(66, 3, 'incident.created', 'flood_incident', 6, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20260930-6D46CFD1\",\"priority\":\"high\"}', '2026-09-30 09:09:12'),
(67, 3, 'flood_report.approved', 'flood_report', 6, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-09-30 09:09:12'),
(68, 3, 'assignment.created', 'incident_assignment', 6, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_id\":6,\"team_id\":1}', '2026-09-30 09:09:37'),
(69, 5, 'assignment.accepted', 'incident_assignment', 6, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-09-30 09:10:21'),
(70, 1, 'user.created', 'user', 10, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"full_name\":\"Kipp Jene Bautista\",\"email\":\"kip1@example.com\",\"role\":\"barangay_personnel\",\"account_status\":\"active\"}', '2026-10-01 02:37:26'),
(71, 1, 'user.deleted', 'user', 10, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"id\":10,\"full_name\":\"Kipp Jene Bautista\",\"email\":\"kip1@example.com\",\"account_status\":\"active\",\"token_version\":1,\"role_slug\":\"barangay_personnel\",\"role_name\":\"Barangay Personnel\"}', NULL, '2026-10-01 02:37:46'),
(72, 1, 'user.created', 'user', 11, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"full_name\":\"Kipp Jene Bautista\",\"email\":\"kip1@example.com\",\"role\":\"responder\",\"account_status\":\"active\"}', '2026-10-01 02:38:44'),
(73, 1, 'resident_account.approve', 'user', 12, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"approved\",\"reason\":null}', '2026-10-01 02:45:39'),
(74, 12, 'community_post.created', 'community_post', 5, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20261001-B632686E\",\"status\":\"submitted\"}', '2026-10-01 02:49:09'),
(75, 3, 'community_post.published', 'community_post', 5, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"published\",\"notes\":null}', '2026-10-01 02:49:55'),
(76, 12, 'flood_report.created', 'flood_report', 7, '136.158.10.90', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20261001-EB55CC81\",\"status\":\"submitted\",\"immediate_danger\":true}', '2026-10-01 02:50:58'),
(77, 3, 'response_team.created', 'response_team', 2, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"team_name\":\"Team B\"}', '2026-10-01 02:52:07'),
(78, 3, 'response_team.member_added', 'response_team', 2, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"responder_user_id\":11}', '2026-10-01 02:52:16'),
(79, 3, 'incident.created', 'flood_incident', 7, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20261001-7DD35169\",\"priority\":\"urgent\"}', '2026-10-01 02:52:51'),
(80, 3, 'flood_report.approved', 'flood_report', 7, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-10-01 02:52:51'),
(81, 3, 'assignment.created', 'incident_assignment', 7, '136.158.10.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_id\":7,\"team_id\":2}', '2026-10-01 02:52:59'),
(82, 11, 'assignment.accepted', 'incident_assignment', 7, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"assigned\"}', '{\"status\":\"accepted\",\"notes\":null}', '2026-10-01 02:53:07'),
(83, 11, 'assignment.en_route', 'incident_assignment', 7, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"accepted\"}', '{\"status\":\"en_route\",\"notes\":null}', '2026-10-01 02:53:11'),
(84, 11, 'assignment.on_scene', 'incident_assignment', 7, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"en_route\"}', '{\"status\":\"on_scene\",\"notes\":null}', '2026-10-01 02:53:13'),
(85, 11, 'assignment.completed', 'incident_assignment', 7, '136.158.10.90', 'Dart/3.13 (dart:io)', '{\"status\":\"on_scene\"}', '{\"status\":\"completed\",\"notes\":\"Good\"}', '2026-10-01 03:45:35'),
(86, 1, 'resident_account.approve', 'user', 13, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"approval_status\":\"pending\",\"account_status\":\"pending\"}', '{\"approval_status\":\"approved\",\"reason\":null}', '2026-10-01 08:55:01'),
(87, 13, 'community_post.created', 'community_post', 6, '175.158.205.112', 'Dart/3.13 (dart:io)', NULL, '{\"post_number\":\"FG-POST-20261001-229B3A7D\",\"status\":\"submitted\"}', '2026-10-01 08:56:36'),
(88, 13, 'flood_report.created', 'flood_report', 8, '175.158.205.112', 'Dart/3.13 (dart:io)', NULL, '{\"report_number\":\"FG-RPT-20261001-16045EBF\",\"status\":\"submitted\",\"immediate_danger\":true}', '2026-10-01 09:14:52'),
(89, 3, 'incident.created', 'flood_incident', 8, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_number\":\"FG-INC-20261001-4FB90D39\",\"priority\":\"medium\"}', '2026-10-01 09:15:40'),
(90, 3, 'flood_report.approved', 'flood_report', 8, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '{\"status\":\"submitted\"}', '{\"status\":\"approved\",\"reason\":null}', '2026-10-01 09:15:40'),
(91, 3, 'response_team.created', 'response_team', 3, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"team_name\":\"Team C\"}', '2026-10-01 09:16:15'),
(92, 3, 'response_team.member_added', 'response_team', 3, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"responder_user_id\":11}', '2026-10-01 09:16:33'),
(93, 3, 'assignment.created', 'incident_assignment', 8, '131.226.101.203', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', NULL, '{\"incident_id\":8,\"team_id\":2}', '2026-10-01 09:17:21');

-- --------------------------------------------------------

--
-- Table structure for table `community_posts`
--

CREATE TABLE `community_posts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `post_number` varchar(40) NOT NULL,
  `resident_user_id` bigint(20) UNSIGNED NOT NULL,
  `category` varchar(50) NOT NULL DEFAULT 'spillway_update',
  `title` varchar(150) NOT NULL,
  `content` text NOT NULL,
  `location_name` varchar(180) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `status` enum('submitted','under_review','revision_requested','approved','rejected','published','archived') NOT NULL DEFAULT 'submitted',
  `reviewer_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `reviewed_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `community_posts`
--

INSERT INTO `community_posts` (`id`, `post_number`, `resident_user_id`, `category`, `title`, `content`, `location_name`, `latitude`, `longitude`, `status`, `reviewer_user_id`, `review_notes`, `submitted_at`, `reviewed_at`, `published_at`, `created_at`, `updated_at`) VALUES
(1, 'FG-POST-20260920-32BDF5D0', 2, 'flood_update', 'Flood', 'Gutter Deep flood in spillway bridge', NULL, NULL, NULL, 'published', 3, NULL, '2026-09-20 23:23:25', '2026-09-20 23:30:49', '2026-09-20 23:30:49', '2026-09-20 15:23:25', '2026-09-20 15:30:49'),
(3, 'FG-POST-20260926-59466795', 7, 'spillway_update', 'Truck Accident', 'Truck is swept away by the current of the river', 'Spillway Bridge', 14.7416739, 121.1637863, 'published', 3, NULL, '2026-09-26 09:12:29', '2026-09-26 09:13:08', '2026-09-26 09:13:08', '2026-09-26 09:12:29', '2026-09-26 09:13:08'),
(5, 'FG-POST-20261001-B632686E', 12, 'spillway_update', 'Water Rising', 'do not cross heavy current', 'Spillway Bridge Montalban', 14.7416774, 121.1637907, 'published', 3, NULL, '2026-10-01 10:49:09', '2026-10-01 10:49:55', '2026-10-01 10:49:55', '2026-10-01 02:49:09', '2026-10-01 02:49:55'),
(6, 'FG-POST-20261001-229B3A7D', 13, 'spillway_update', 'sample', 'flood', NULL, 14.7325805, 121.0594878, 'submitted', NULL, NULL, '2026-10-01 16:56:36', NULL, NULL, '2026-10-01 08:56:36', '2026-10-01 08:56:36');

-- --------------------------------------------------------

--
-- Table structure for table `community_post_photos`
--

CREATE TABLE `community_post_photos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `community_post_id` bigint(20) UNSIGNED NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `file_size_bytes` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `community_post_photos`
--

INSERT INTO `community_post_photos` (`id`, `community_post_id`, `file_path`, `original_filename`, `mime_type`, `file_size_bytes`, `created_at`) VALUES
(1, 1, 'storage/private/report_photos/8a9e67d9dce66ca9842096636d13c4a34014026a0d4fcc49.jpg', 'scaled_3f417063-c5aa-4fd8-bb29-f062e3874a164447899509623475619.jpg', 'image/jpeg', 27533, '2026-09-20 15:23:25'),
(3, 3, 'storage/private/report_photos/4b2cad081d3608f8b00d4cf94bdf1e3c451a5a303745ced8.jpg', 'scaled_6971.jpg', 'image/jpeg', 423577, '2026-09-26 09:12:29'),
(5, 5, 'storage/private/report_photos/95d34026940167413eaa0d0ccc12575360ca931d87d795ae.jpg', 'scaled_6968.jpg', 'image/jpeg', 604736, '2026-10-01 02:49:09'),
(6, 6, 'storage/private/report_photos/7439e0d207c5c8c03e91c61324b9f827261003098598d4f4.jpg', 'scaled_7132.jpg', 'image/jpeg', 430435, '2026-10-01 08:56:36');

-- --------------------------------------------------------

--
-- Table structure for table `community_post_status_history`
--

CREATE TABLE `community_post_status_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `community_post_id` bigint(20) UNSIGNED NOT NULL,
  `previous_status` varchar(40) DEFAULT NULL,
  `new_status` varchar(40) NOT NULL,
  `changed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `community_post_status_history`
--

INSERT INTO `community_post_status_history` (`id`, `community_post_id`, `previous_status`, `new_status`, `changed_by_user_id`, `notes`, `created_at`) VALUES
(1, 1, NULL, 'submitted', 2, NULL, '2026-09-20 15:23:25'),
(2, 1, 'submitted', 'under_review', 3, NULL, '2026-09-20 15:30:41'),
(3, 1, 'under_review', 'published', 3, NULL, '2026-09-20 15:30:49'),
(6, 3, NULL, 'submitted', 7, NULL, '2026-09-26 09:12:29'),
(7, 3, 'submitted', 'published', 3, NULL, '2026-09-26 09:13:08'),
(10, 5, NULL, 'submitted', 12, NULL, '2026-10-01 02:49:09'),
(11, 5, 'submitted', 'published', 3, NULL, '2026-10-01 02:49:55'),
(12, 6, NULL, 'submitted', 13, NULL, '2026-10-01 08:56:36');

-- --------------------------------------------------------

--
-- Table structure for table `device_commands`
--

CREATE TABLE `device_commands` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `device_id` varchar(50) NOT NULL DEFAULT 'FG-STATION-001',
  `command_type` varchar(50) NOT NULL,
  `command_value` varchar(150) DEFAULT NULL,
  `parameters_json` text DEFAULT NULL,
  `command_status` enum('pending','claimed','completed','failed','expired','cancelled') NOT NULL DEFAULT 'pending',
  `requested_by` int(10) UNSIGNED DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `result_message` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `claimed_at` datetime DEFAULT NULL,
  `expires_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `device_commands`
--

INSERT INTO `device_commands` (`id`, `device_id`, `command_type`, `command_value`, `parameters_json`, `command_status`, `requested_by`, `sent_at`, `completed_at`, `result_message`, `requested_at`, `claimed_at`, `expires_at`) VALUES
(1, 'FG-STATION-001', 'siren_on', NULL, '{\"duration_ms\":60000,\"audio_file\":null}', 'expired', 2, NULL, '2026-08-24 14:34:26', 'Command expired before device retrieval.', '2026-08-24 06:13:45', NULL, '2026-08-24 14:15:45'),
(2, 'FG-STATION-001', 'siren_off', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'expired', 2, NULL, '2026-08-24 14:34:26', 'Command expired before device retrieval.', '2026-08-24 06:14:06', NULL, '2026-08-24 14:16:06'),
(3, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'expired', 2, NULL, '2026-08-24 14:34:26', 'Command expired before device retrieval.', '2026-08-24 06:14:18', NULL, '2026-08-24 14:16:18'),
(4, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'expired', 2, NULL, '2026-08-24 14:34:26', 'Command expired before device retrieval.', '2026-08-24 06:15:34', NULL, '2026-08-24 14:17:34'),
(5, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:35:49', 'Siren test started with automatic timeout.', '2026-08-24 06:35:42', '2026-08-24 14:35:48', '2026-08-24 14:37:42'),
(6, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:36:07', 'Siren test started with automatic timeout.', '2026-08-24 06:36:02', '2026-08-24 14:36:06', '2026-08-24 14:38:02'),
(7, 'FG-STATION-001', 'siren_on', NULL, '{\"duration_ms\":60000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:36:22', 'Siren activated with 60-second maximum safety timeout.', '2026-08-24 06:36:17', '2026-08-24 14:36:21', '2026-08-24 14:38:17'),
(8, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:41:16', 'Siren test started with automatic timeout.', '2026-08-24 06:41:11', '2026-08-24 14:41:16', '2026-08-24 14:43:11'),
(9, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 14:41:28', 'Voice alert playback started.', '2026-08-24 06:41:25', '2026-08-24 14:41:27', '2026-08-24 14:43:25'),
(10, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 14:41:42', 'Voice alert playback started.', '2026-08-24 06:41:38', '2026-08-24 14:41:42', '2026-08-24 14:43:38'),
(11, 'FG-STATION-001', 'stop_audio', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:41:52', 'Voice playback stopped.', '2026-08-24 06:41:45', '2026-08-24 14:41:52', '2026-08-24 14:43:45'),
(12, 'FG-STATION-001', 'request_reading', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:42:02', 'Immediate sensor upload requested.', '2026-08-24 06:41:57', '2026-08-24 14:42:02', '2026-08-24 14:43:57'),
(13, 'FG-STATION-001', 'maintenance_on', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:45:10', 'Maintenance mode enabled.', '2026-08-24 06:44:55', '2026-08-24 14:45:09', '2026-08-24 14:47:55'),
(14, 'FG-STATION-001', 'maintenance_off', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:53:11', 'Maintenance mode disabled.', '2026-08-24 06:53:09', '2026-08-24 14:53:09', '2026-08-24 14:56:09'),
(15, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 14:53:50', 'Siren test started with automatic timeout.', '2026-08-24 06:53:46', '2026-08-24 14:53:49', '2026-08-24 14:55:46'),
(16, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 14:53:58', 'Voice alert playback started.', '2026-08-24 06:53:54', '2026-08-24 14:53:58', '2026-08-24 14:55:54'),
(17, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 15:06:43', 'Siren test started with automatic timeout.', '2026-08-24 07:06:40', '2026-08-24 15:06:42', '2026-08-24 15:08:40'),
(18, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 15:07:01', 'Voice alert playback started.', '2026-08-24 07:06:55', '2026-08-24 15:07:00', '2026-08-24 15:08:55'),
(19, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'failed', 2, NULL, '2026-08-24 15:45:19', 'DFPlayer is not ready.', '2026-08-24 07:45:16', '2026-08-24 15:45:19', '2026-08-24 15:47:16'),
(20, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'failed', 2, NULL, '2026-08-24 15:46:14', 'DFPlayer is not ready.', '2026-08-24 07:46:09', '2026-08-24 15:46:13', '2026-08-24 15:48:09'),
(21, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'failed', 2, NULL, '2026-08-24 15:47:52', 'DFPlayer is not ready.', '2026-08-24 07:47:47', '2026-08-24 15:47:51', '2026-08-24 15:49:47'),
(22, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-24 15:54:41', 'Siren test started with automatic timeout.', '2026-08-24 07:54:35', '2026-08-24 15:54:40', '2026-08-24 15:56:35'),
(23, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 16:04:51', 'Voice alert playback started.', '2026-08-24 08:04:48', '2026-08-24 16:04:50', '2026-08-24 16:06:48'),
(24, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-24 16:08:14', 'Voice alert playback started.', '2026-08-24 08:08:06', '2026-08-24 16:08:14', '2026-08-24 16:10:06'),
(25, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-25 23:03:53', 'Voice alert playback started.', '2026-08-25 15:03:45', '2026-08-25 23:03:49', '2026-08-25 23:05:45'),
(26, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-25 23:06:13', 'Voice alert playback started.', '2026-08-25 15:06:06', '2026-08-25 23:06:13', '2026-08-25 23:08:06'),
(27, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-25 23:06:56', 'Voice alert playback started.', '2026-08-25 15:06:54', '2026-08-25 23:06:55', '2026-08-25 23:08:54'),
(28, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-25 23:09:25', 'Voice alert playback started.', '2026-08-25 15:09:20', '2026-08-25 23:09:24', '2026-08-25 23:11:20'),
(29, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-08-26 01:25:43', 'Siren test started with automatic timeout.', '2026-08-25 17:25:35', '2026-08-26 01:25:42', '2026-08-26 01:27:35'),
(30, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-26 01:26:00', 'Voice alert playback started.', '2026-08-25 17:25:54', '2026-08-26 01:25:59', '2026-08-26 01:27:54'),
(31, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'failed', 2, NULL, '2026-08-26 06:23:07', 'DFPlayer is not ready.', '2026-08-25 22:23:04', '2026-08-26 06:23:06', '2026-08-26 06:25:04'),
(32, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'failed', 2, NULL, '2026-08-26 06:24:18', 'DFPlayer is not ready.', '2026-08-25 22:24:05', '2026-08-26 06:24:18', '2026-08-26 06:26:05'),
(33, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-08-26 06:27:04', 'Voice alert playback started.', '2026-08-25 22:26:58', '2026-08-26 06:27:03', '2026-08-26 06:28:58'),
(34, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 02:47:29', 'Voice alert playback started.', '2026-09-30 18:47:23', '2026-10-01 02:47:27', '2026-10-01 02:49:23'),
(35, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 02:48:23', 'Barrier opening blocked by an obstacle or stale sensor.', '2026-09-30 18:48:20', '2026-10-01 02:48:21', '2026-10-01 02:50:20'),
(36, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 02:53:18', 'North and South barriers are closing.', '2026-09-30 18:53:16', '2026-10-01 02:53:16', '2026-10-01 02:55:16'),
(37, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 02:53:46', 'Barrier opening blocked by an obstacle or stale sensor.', '2026-09-30 18:53:41', '2026-10-01 02:53:44', '2026-10-01 02:55:41'),
(38, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 02:54:08', 'Barrier opening blocked by an obstacle or stale sensor.', '2026-09-30 18:54:00', '2026-10-01 02:54:06', '2026-10-01 02:56:00'),
(39, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 03:08:10', 'Voice alert playback started.', '2026-09-30 19:08:08', '2026-10-01 03:08:08', '2026-10-01 03:10:08'),
(40, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 03:16:28', 'Voice alert playback started.', '2026-09-30 19:16:25', '2026-10-01 03:16:26', '2026-10-01 03:18:25'),
(41, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:23:43', 'North and South barriers are closing.', '2026-09-30 19:23:36', '2026-10-01 03:23:41', '2026-10-01 03:25:36'),
(42, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:29:14', 'North and South barriers are closing.', '2026-09-30 19:29:10', '2026-10-01 03:29:12', '2026-10-01 03:31:10'),
(43, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:34:37', 'North and South barriers are closing.', '2026-09-30 19:34:33', '2026-10-01 03:34:35', '2026-10-01 03:36:33'),
(44, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:35:17', 'North and South barriers are opening.', '2026-09-30 19:35:10', '2026-10-01 03:35:15', '2026-10-01 03:37:10'),
(45, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:36:16', 'North and South barriers are closing.', '2026-09-30 19:36:11', '2026-10-01 03:36:14', '2026-10-01 03:38:11'),
(46, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:36:29', 'North and South barriers are opening.', '2026-09-30 19:36:27', '2026-10-01 03:36:27', '2026-10-01 03:38:27'),
(47, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:41:21', 'North and South barriers are closing.', '2026-09-30 19:41:11', '2026-10-01 03:41:19', '2026-10-01 03:43:11'),
(48, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:41:38', 'North and South barriers are opening.', '2026-09-30 19:41:32', '2026-10-01 03:41:36', '2026-10-01 03:43:32'),
(49, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:41:51', 'North and South barriers are closing.', '2026-09-30 19:41:44', '2026-10-01 03:41:49', '2026-10-01 03:43:44'),
(50, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 03:43:57', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-09-30 19:43:53', '2026-10-01 03:43:55', '2026-10-01 03:45:53'),
(51, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 03:45:26', 'Voice alert playback started.', '2026-09-30 19:45:24', '2026-10-01 03:45:24', '2026-10-01 03:47:24'),
(52, 'FG-STATION-001', 'stop_audio', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:45:38', 'Voice playback stopped.', '2026-09-30 19:45:30', '2026-10-01 03:45:35', '2026-10-01 03:47:30'),
(53, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 03:45:44', 'Siren test started with automatic timeout.', '2026-09-30 19:45:41', '2026-10-01 03:45:42', '2026-10-01 03:47:41'),
(54, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 13:16:38', 'Voice alert playback started.', '2026-10-01 05:16:34', '2026-10-01 13:16:36', '2026-10-01 13:18:34'),
(55, 'FG-STATION-001', 'stop_audio', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 13:16:46', 'Voice playback stopped.', '2026-10-01 05:16:42', '2026-10-01 13:16:43', '2026-10-01 13:18:42'),
(56, 'FG-STATION-001', 'siren_test', NULL, '{\"duration_ms\":3000,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 13:16:50', 'Siren test started with automatic timeout.', '2026-10-01 05:16:47', '2026-10-01 13:16:48', '2026-10-01 13:18:47'),
(57, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:17:03', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:16:59', '2026-10-01 13:17:00', '2026-10-01 13:18:59'),
(58, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:17:38', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:17:36', '2026-10-01 13:17:36', '2026-10-01 13:19:36'),
(59, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:17:59', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:17:53', '2026-10-01 13:17:56', '2026-10-01 13:19:53'),
(60, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:18:39', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:18:34', '2026-10-01 13:18:37', '2026-10-01 13:20:34'),
(61, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:21:20', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:21:14', '2026-10-01 13:21:18', '2026-10-01 13:23:14'),
(62, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:23:26', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:23:21', '2026-10-01 13:23:24', '2026-10-01 13:25:21'),
(63, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:23:41', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:23:35', '2026-10-01 13:23:39', '2026-10-01 13:25:35'),
(64, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:25:10', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:25:01', '2026-10-01 13:25:08', '2026-10-01 13:27:01'),
(65, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:25:25', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:25:20', '2026-10-01 13:25:23', '2026-10-01 13:27:20'),
(66, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:27:29', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:27:24', '2026-10-01 13:27:27', '2026-10-01 13:29:24'),
(67, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:46:42', 'Barrier closing blocked by an obstacle or stale sensor.', '2026-10-01 05:46:39', '2026-10-01 13:46:40', '2026-10-01 13:48:39'),
(68, 'FG-STATION-001', 'barrier_close', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 13:51:26', 'North and South barriers are closing.', '2026-10-01 05:51:22', '2026-10-01 13:51:24', '2026-10-01 13:53:22'),
(69, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'failed', 2, NULL, '2026-10-01 13:51:38', 'Barrier opening blocked by an obstacle or stale sensor.', '2026-10-01 05:51:34', '2026-10-01 13:51:36', '2026-10-01 13:53:34'),
(70, 'FG-STATION-001', 'barrier_open', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 13:51:49', 'North and South barriers are opening.', '2026-10-01 05:51:43', '2026-10-01 13:51:47', '2026-10-01 13:53:43'),
(71, 'FG-STATION-001', 'play_voice', NULL, '{\"duration_ms\":0,\"audio_file\":1}', 'completed', 2, NULL, '2026-10-01 15:55:04', 'Voice alert playback started.', '2026-10-01 07:54:58', '2026-10-01 15:55:00', '2026-10-01 15:56:58'),
(72, 'FG-STATION-001', 'stop_audio', NULL, '{\"duration_ms\":0,\"audio_file\":null}', 'completed', 2, NULL, '2026-10-01 15:55:09', 'Voice playback stopped.', '2026-10-01 07:55:04', '2026-10-01 15:55:06', '2026-10-01 15:57:04');

-- --------------------------------------------------------

--
-- Table structure for table `device_commands_backup_20260822`
--

CREATE TABLE `device_commands_backup_20260822` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `command_type` varchar(50) NOT NULL,
  `command_value` varchar(150) DEFAULT NULL,
  `command_status` enum('pending','sent','acknowledged','failed','cancelled') NOT NULL DEFAULT 'pending',
  `requested_by` int(10) UNSIGNED DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `acknowledged_at` datetime DEFAULT NULL,
  `device_response` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `device_events`
--

CREATE TABLE `device_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `monitoring_device_id` bigint(20) UNSIGNED NOT NULL,
  `sensor_reading_id` bigint(20) UNSIGNED DEFAULT NULL,
  `event_type` varchar(50) NOT NULL,
  `severity` enum('info','warning','critical') NOT NULL DEFAULT 'info',
  `title` varchar(150) NOT NULL,
  `details_json` longtext DEFAULT NULL,
  `occurred_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_events`
--

INSERT INTO `device_events` (`id`, `monitoring_device_id`, `sensor_reading_id`, `event_type`, `severity`, `title`, `details_json`, `occurred_at`, `created_at`) VALUES
(1, 1, 554, 'device_online', 'info', 'Monitoring station is online', NULL, '2026-09-08 11:19:28', '2026-09-08 03:19:28'),
(2, 1, NULL, 'device_offline', 'critical', 'Monitoring station is offline', '{\"timeout_seconds\":90}', '2026-09-08 11:28:25', '2026-09-08 03:28:25'),
(3, 1, 556, 'device_online', 'info', 'Monitoring station is online', NULL, '2026-09-08 11:31:01', '2026-09-08 03:31:01'),
(4, 1, 557, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"not_connected\"}', '2026-09-10 10:48:48', '2026-09-10 02:48:48'),
(5, 1, 557, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"not_connected\"}', '2026-09-10 10:48:48', '2026-09-10 02:48:48'),
(6, 1, 558, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-09-10 10:56:56', '2026-09-10 02:56:56'),
(7, 1, 559, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-09-10 13:50:12', '2026-09-10 05:50:12'),
(8, 1, 560, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-09-20 10:47:50', '2026-09-20 02:47:50'),
(9, 1, 562, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"warning\",\"to\":\"critical\"}', '2026-09-28 20:01:12', '2026-09-28 12:01:12'),
(10, 1, 563, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"critical\",\"to\":\"normal\"}', '2026-09-28 20:02:49', '2026-09-28 12:02:49'),
(11, 1, 564, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"not_connected\",\"to\":\"blocked\"}', '2026-10-01 02:46:41', '2026-09-30 18:46:41'),
(12, 1, 564, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"not_connected\",\"to\":\"blocked\"}', '2026-10-01 02:46:41', '2026-09-30 18:46:41'),
(13, 1, 565, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 02:49:15', '2026-09-30 18:49:15'),
(14, 1, 566, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 02:50:17', '2026-09-30 18:50:17'),
(15, 1, 567, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"normal\",\"to\":\"critical\"}', '2026-10-01 02:50:35', '2026-09-30 18:50:35'),
(16, 1, 567, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 02:50:35', '2026-09-30 18:50:35'),
(17, 1, 568, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"critical\",\"to\":\"normal\"}', '2026-10-01 02:51:00', '2026-09-30 18:51:00'),
(18, 1, 568, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 02:51:00', '2026-09-30 18:51:00'),
(19, 1, 569, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 02:53:03', '2026-09-30 18:53:03'),
(20, 1, 569, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"opening\"}', '2026-10-01 02:53:03', '2026-09-30 18:53:03'),
(21, 1, 570, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"paused\"}', '2026-10-01 02:53:21', '2026-09-30 18:53:21'),
(22, 1, 570, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"opening\",\"to\":\"closing\"}', '2026-10-01 02:53:21', '2026-09-30 18:53:21'),
(23, 1, 571, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"paused\",\"to\":\"blocked\"}', '2026-10-01 02:53:53', '2026-09-30 18:53:53'),
(24, 1, 571, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"blocked\"}', '2026-10-01 02:53:53', '2026-09-30 18:53:53'),
(25, 1, 572, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"paused\"}', '2026-10-01 02:54:53', '2026-09-30 18:54:53'),
(26, 1, 573, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 02:55:23', '2026-09-30 18:55:23'),
(27, 1, 574, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"paused\",\"to\":\"blocked\"}', '2026-10-01 02:55:53', '2026-09-30 18:55:53'),
(28, 1, 577, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 03:14:37', '2026-09-30 19:14:37'),
(29, 1, 578, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 03:15:07', '2026-09-30 19:15:07'),
(30, 1, 579, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 03:16:08', '2026-09-30 19:16:08'),
(31, 1, 579, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 03:16:08', '2026-09-30 19:16:08'),
(32, 1, 580, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 03:17:38', '2026-09-30 19:17:38'),
(33, 1, 582, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 03:23:13', '2026-09-30 19:23:13'),
(34, 1, 582, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 03:23:13', '2026-09-30 19:23:13'),
(35, 1, 583, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:23:45', '2026-09-30 19:23:45'),
(36, 1, 583, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:23:45', '2026-09-30 19:23:45'),
(37, 1, 584, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"paused\"}', '2026-10-01 03:24:18', '2026-09-30 19:24:18'),
(38, 1, 584, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"closed\"}', '2026-10-01 03:24:18', '2026-09-30 19:24:18'),
(39, 1, 585, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"paused\",\"to\":\"open\"}', '2026-10-01 03:25:48', '2026-09-30 19:25:48'),
(40, 1, 585, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closed\",\"to\":\"open\"}', '2026-10-01 03:25:48', '2026-09-30 19:25:48'),
(41, 1, 586, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:29:16', '2026-09-30 19:29:16'),
(42, 1, 586, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:29:16', '2026-09-30 19:29:16'),
(43, 1, 587, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"closed\"}', '2026-10-01 03:29:49', '2026-09-30 19:29:49'),
(44, 1, 587, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"paused\"}', '2026-10-01 03:29:49', '2026-09-30 19:29:49'),
(45, 1, 588, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closed\",\"to\":\"open\"}', '2026-10-01 03:31:19', '2026-09-30 19:31:19'),
(46, 1, 588, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"paused\",\"to\":\"open\"}', '2026-10-01 03:31:19', '2026-09-30 19:31:19'),
(47, 1, 589, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:34:40', '2026-09-30 19:34:40'),
(48, 1, 589, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:34:40', '2026-09-30 19:34:40'),
(49, 1, 590, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"paused\"}', '2026-10-01 03:35:13', '2026-09-30 19:35:13'),
(50, 1, 590, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"closed\"}', '2026-10-01 03:35:13', '2026-09-30 19:35:13'),
(51, 1, 591, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"paused\",\"to\":\"open\"}', '2026-10-01 03:35:20', '2026-09-30 19:35:20'),
(52, 1, 591, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closed\",\"to\":\"opening\"}', '2026-10-01 03:35:20', '2026-09-30 19:35:20'),
(53, 1, 592, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"opening\",\"to\":\"paused\"}', '2026-10-01 03:35:52', '2026-09-30 19:35:52'),
(54, 1, 593, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:36:19', '2026-09-30 19:36:19'),
(55, 1, 593, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"paused\",\"to\":\"closed\"}', '2026-10-01 03:36:19', '2026-09-30 19:36:19'),
(56, 1, 594, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"open\"}', '2026-10-01 03:36:33', '2026-09-30 19:36:33'),
(57, 1, 594, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closed\",\"to\":\"open\"}', '2026-10-01 03:36:33', '2026-09-30 19:36:33'),
(58, 1, 595, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:41:24', '2026-09-30 19:41:24'),
(59, 1, 595, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:41:24', '2026-09-30 19:41:24'),
(60, 1, 596, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"opening\"}', '2026-10-01 03:41:41', '2026-09-30 19:41:41'),
(61, 1, 596, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"open\"}', '2026-10-01 03:41:41', '2026-09-30 19:41:41'),
(62, 1, 597, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"opening\",\"to\":\"closing\"}', '2026-10-01 03:41:54', '2026-09-30 19:41:54'),
(63, 1, 597, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 03:41:54', '2026-09-30 19:41:54'),
(64, 1, 598, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"paused\"}', '2026-10-01 03:42:26', '2026-09-30 19:42:26'),
(65, 1, 598, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closing\",\"to\":\"closed\"}', '2026-10-01 03:42:26', '2026-09-30 19:42:26'),
(66, 1, 599, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"paused\",\"to\":\"open\"}', '2026-10-01 03:43:02', '2026-09-30 19:43:02'),
(67, 1, 599, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"closed\",\"to\":\"open\"}', '2026-10-01 03:43:02', '2026-09-30 19:43:02'),
(68, 1, 600, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 10:11:26', '2026-10-01 02:11:26'),
(69, 1, 600, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 10:11:26', '2026-10-01 02:11:26'),
(70, 1, 603, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"normal\",\"to\":\"critical\"}', '2026-10-01 11:12:26', '2026-10-01 03:12:26'),
(71, 1, 605, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"critical\",\"to\":\"normal\"}', '2026-10-01 11:14:56', '2026-10-01 03:14:56'),
(72, 1, 608, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-10-01 11:19:47', '2026-10-01 03:19:47'),
(73, 1, 610, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"warning\",\"to\":\"critical\"}', '2026-10-01 11:22:39', '2026-10-01 03:22:39'),
(74, 1, 612, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"critical\",\"to\":\"warning\"}', '2026-10-01 11:23:18', '2026-10-01 03:23:18'),
(75, 1, 614, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-10-01 11:29:12', '2026-10-01 03:29:12'),
(76, 1, 615, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"normal\",\"to\":\"critical\"}', '2026-10-01 11:29:22', '2026-10-01 03:29:22'),
(77, 1, 616, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"critical\",\"to\":\"warning\"}', '2026-10-01 11:29:55', '2026-10-01 03:29:55'),
(78, 1, 617, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"warning\",\"to\":\"critical\"}', '2026-10-01 11:31:27', '2026-10-01 03:31:27'),
(79, 1, 618, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"critical\",\"to\":\"warning\"}', '2026-10-01 11:31:45', '2026-10-01 03:31:45'),
(80, 1, 619, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-10-01 12:33:22', '2026-10-01 04:33:22'),
(81, 1, 624, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-10-01 13:07:54', '2026-10-01 05:07:54'),
(82, 1, 625, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-10-01 13:10:50', '2026-10-01 05:10:50'),
(83, 1, 626, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 13:16:13', '2026-10-01 05:16:13'),
(84, 1, 630, 'barrier_state_changed', 'critical', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 13:28:54', '2026-10-01 05:28:54'),
(85, 1, 631, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 13:29:26', '2026-10-01 05:29:26'),
(86, 1, 634, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 13:51:16', '2026-10-01 05:51:16'),
(87, 1, 635, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 13:51:29', '2026-10-01 05:51:29'),
(88, 1, 635, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"paused\"}', '2026-10-01 13:51:29', '2026-10-01 05:51:29'),
(89, 1, 636, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"opening\"}', '2026-10-01 13:51:52', '2026-10-01 05:51:52'),
(90, 1, 637, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"opening\",\"to\":\"open\"}', '2026-10-01 13:52:31', '2026-10-01 05:52:31'),
(91, 1, 637, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"paused\",\"to\":\"open\"}', '2026-10-01 13:52:31', '2026-10-01 05:52:31'),
(92, 1, 638, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 15:53:11', '2026-10-01 07:53:11'),
(93, 1, 639, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 15:54:42', '2026-10-01 07:54:42'),
(94, 1, 641, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-10-01 15:56:22', '2026-10-01 07:56:22'),
(95, 1, 642, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-10-01 15:57:01', '2026-10-01 07:57:01'),
(96, 1, 643, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 15:57:35', '2026-10-01 07:57:35'),
(97, 1, 646, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 16:26:58', '2026-10-01 08:26:58'),
(98, 1, 647, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 16:27:29', '2026-10-01 08:27:29'),
(99, 1, 649, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 16:34:06', '2026-10-01 08:34:06'),
(100, 1, 650, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 16:34:37', '2026-10-01 08:34:37'),
(101, 1, 651, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 16:38:44', '2026-10-01 08:38:44'),
(102, 1, 652, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 16:39:14', '2026-10-01 08:39:14'),
(103, 1, 654, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 16:47:56', '2026-10-01 08:47:56'),
(104, 1, 655, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 16:48:27', '2026-10-01 08:48:27'),
(105, 1, 656, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 16:49:58', '2026-10-01 08:49:58'),
(106, 1, 657, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 16:50:29', '2026-10-01 08:50:29'),
(107, 1, 660, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 17:03:14', '2026-10-01 09:03:14'),
(108, 1, 661, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 17:03:44', '2026-10-01 09:03:44'),
(109, 1, 662, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 17:04:14', '2026-10-01 09:04:14'),
(110, 1, 663, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 17:04:45', '2026-10-01 09:04:45'),
(111, 1, 665, 'alert_transition', 'critical', 'Alert level changed to Critical', '{\"from\":\"normal\",\"to\":\"critical\"}', '2026-10-01 17:05:54', '2026-10-01 09:05:54'),
(112, 1, 665, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"open\",\"to\":\"closing\"}', '2026-10-01 17:05:54', '2026-10-01 09:05:54'),
(113, 1, 666, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"critical\",\"to\":\"warning\"}', '2026-10-01 17:06:04', '2026-10-01 09:06:04'),
(114, 1, 666, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closing\",\"to\":\"closed\"}', '2026-10-01 17:06:04', '2026-10-01 09:06:04'),
(115, 1, 667, 'alert_transition', 'info', 'Alert level changed to Normal', '{\"from\":\"warning\",\"to\":\"normal\"}', '2026-10-01 17:06:26', '2026-10-01 09:06:26'),
(116, 1, 668, 'barrier_state_changed', 'info', 'North Barrier Status changed', '{\"from\":\"closed\",\"to\":\"open\"}', '2026-10-01 17:06:58', '2026-10-01 09:06:58'),
(117, 1, 669, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 17:07:59', '2026-10-01 09:07:59'),
(118, 1, 670, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 17:08:29', '2026-10-01 09:08:29'),
(119, 1, 671, 'alert_transition', 'warning', 'Alert level changed to Warning', '{\"from\":\"normal\",\"to\":\"warning\"}', '2026-10-01 17:11:06', '2026-10-01 09:11:06'),
(120, 1, 674, 'barrier_state_changed', 'info', 'South Barrier Status changed', '{\"from\":\"blocked\",\"to\":\"open\"}', '2026-10-01 17:23:52', '2026-10-01 09:23:52'),
(121, 1, 675, 'barrier_state_changed', 'critical', 'South Barrier Status changed', '{\"from\":\"open\",\"to\":\"blocked\"}', '2026-10-01 17:24:23', '2026-10-01 09:24:23');

-- --------------------------------------------------------

--
-- Table structure for table `device_latest_readings`
--

CREATE TABLE `device_latest_readings` (
  `monitoring_device_id` bigint(20) UNSIGNED NOT NULL,
  `sensor_reading_id` bigint(20) UNSIGNED DEFAULT NULL,
  `water_distance_cm` decimal(8,2) DEFAULT NULL,
  `water_level_cm` decimal(8,2) DEFAULT NULL,
  `sensor_health` enum('healthy','suspect','fault','unknown') NOT NULL DEFAULT 'unknown',
  `rain_analog` int(10) UNSIGNED DEFAULT NULL,
  `rain_detected` tinyint(1) NOT NULL DEFAULT 0,
  `wind_speed_mps` decimal(8,2) DEFAULT NULL,
  `north_obstacle` tinyint(1) NOT NULL DEFAULT 0,
  `south_obstacle` tinyint(1) NOT NULL DEFAULT 0,
  `north_barrier_status` enum('open','closed','opening','closing','paused','blocked','fault','not_connected','unknown') NOT NULL DEFAULT 'unknown',
  `south_barrier_status` enum('open','closed','opening','closing','paused','blocked','fault','not_connected','unknown') NOT NULL DEFAULT 'unknown',
  `battery_voltage` decimal(6,2) DEFAULT NULL,
  `battery_percent` decimal(5,2) DEFAULT NULL,
  `alert_level` enum('normal','warning','critical') NOT NULL DEFAULT 'normal',
  `device_status` enum('online','offline','sensor_error','maintenance') NOT NULL DEFAULT 'online',
  `measured_at` datetime NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `device_latest_readings`
--

INSERT INTO `device_latest_readings` (`monitoring_device_id`, `sensor_reading_id`, `water_distance_cm`, `water_level_cm`, `sensor_health`, `rain_analog`, `rain_detected`, `wind_speed_mps`, `north_obstacle`, `south_obstacle`, `north_barrier_status`, `south_barrier_status`, `battery_voltage`, `battery_percent`, `alert_level`, `device_status`, `measured_at`, `received_at`) VALUES
(1, NULL, 45.20, 0.00, 'healthy', 3425, 1, 0.59, 0, 1, 'open', 'blocked', 12.40, 82.00, 'warning', 'online', '2026-10-01 17:27:25', '2026-10-01 09:27:25');

-- --------------------------------------------------------

--
-- Table structure for table `email_verification_tokens`
--

CREATE TABLE `email_verification_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_verification_tokens`
--

INSERT INTO `email_verification_tokens` (`id`, `user_id`, `token_hash`, `expires_at`, `used_at`, `created_at`) VALUES
(1, 2, '88900b8a6b3416a39076c85e8aed023dbf11e3a519b8683cdb00db77ababf583', '2026-09-08 13:15:26', '2026-09-08 12:45:45', '2026-09-08 04:45:26'),
(2, 6, '66354abeed2a31579ea838dc6ab68e9c3e94a2615299cfb82d221a507d7e9f2b', '2026-09-24 17:28:32', '2026-09-24 16:58:33', '2026-09-24 08:58:32'),
(3, 7, '0f3b3e2b9e2080dfdbf9dc0a901663bebae92ab2cb5bb1b0e060d8d9efc161a9', '2026-09-25 12:48:10', '2026-09-25 12:18:18', '2026-09-25 04:18:11'),
(4, 8, 'fc27e9d45e740649ccbbea0ce7675a6351411db86df354a4957de041767a9c55', '2026-09-25 13:43:48', NULL, '2026-09-25 05:13:49'),
(5, 9, '105d618e2ff32adfa548cec3f93a70df7deec6ff64e21802ca24b47a0c4f19ac', '2026-09-25 13:45:44', '2026-09-25 13:17:18', '2026-09-25 05:15:44'),
(6, 7, 'e2097530e6ff3b4b12611eeef3bc76a477d7ae31f9e31f37bec04e5b8534505f', '2026-09-25 16:24:19', '2026-09-25 15:54:42', '2026-09-25 07:54:19'),
(7, 12, '7f7ad157c1a6e96db17679ebfa7fb9c9d9c186fc9582bf8abef18e25956948ba', '2026-10-01 11:13:10', '2026-10-01 10:43:31', '2026-10-01 02:43:10'),
(8, 13, '65ce524ef1383c1c041b0c08b3d3e749b475652b0e1ea72d40fd2f0d10449a09', '2026-10-01 17:22:55', '2026-10-01 16:53:16', '2026-10-01 08:52:55');

-- --------------------------------------------------------

--
-- Table structure for table `flood_incidents`
--

CREATE TABLE `flood_incidents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `incident_number` varchar(30) NOT NULL,
  `source_report_id` bigint(20) UNSIGNED NOT NULL,
  `priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `status` enum('awaiting_assignment','assigned','accepted','en_route','on_scene','response_in_progress','resolved','closed','cancelled') NOT NULL DEFAULT 'awaiting_assignment',
  `public_approved` tinyint(1) NOT NULL DEFAULT 0,
  `public_location` varchar(255) DEFAULT NULL,
  `public_condition` varchar(1000) DEFAULT NULL,
  `public_water_level_cm` decimal(8,2) DEFAULT NULL,
  `public_approved_by` bigint(20) UNSIGNED DEFAULT NULL,
  `public_approved_at` datetime DEFAULT NULL,
  `resolution_summary` text DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `resolution_verified_by` bigint(20) UNSIGNED DEFAULT NULL,
  `resolution_verified_at` datetime DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flood_incidents`
--

INSERT INTO `flood_incidents` (`id`, `incident_number`, `source_report_id`, `priority`, `status`, `public_approved`, `public_location`, `public_condition`, `public_water_level_cm`, `public_approved_by`, `public_approved_at`, `resolution_summary`, `resolved_at`, `resolution_verified_by`, `resolution_verified_at`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'FG-INC-20260908-BCC05278', 1, 'medium', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'Controlled test completed. The area was assessed and no real emergency occurred.', '2026-09-09 09:33:11', NULL, NULL, 3, '2026-09-08 05:25:50', '2026-09-09 01:33:11'),
(2, 'FG-INC-20260920-8A353242', 2, 'medium', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'Test response completed. Area inspected and the reported flood condition was verified. No immediate danger remains.', '2026-09-20 16:29:26', NULL, NULL, 3, '2026-09-20 07:50:29', '2026-09-20 08:29:26'),
(3, 'FG-INC-20260920-0C700ED5', 3, 'medium', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'all good', '2026-09-21 17:01:28', NULL, NULL, 3, '2026-09-20 14:43:06', '2026-09-21 09:01:28'),
(4, 'FG-INC-20260921-78FDC9C9', 4, 'medium', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'ok', '2026-09-23 15:22:38', NULL, NULL, 3, '2026-09-21 08:53:28', '2026-09-23 07:22:38'),
(5, 'FG-INC-20260926-6AB15B55', 5, 'medium', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'Good', '2026-09-26 09:10:12', NULL, NULL, 3, '2026-09-26 08:36:17', '2026-09-26 09:10:12'),
(6, 'FG-INC-20260930-6D46CFD1', 6, 'high', 'accepted', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, '2026-09-30 09:09:12', '2026-09-30 09:10:21'),
(7, 'FG-INC-20261001-7DD35169', 7, 'urgent', 'resolved', 0, NULL, NULL, NULL, NULL, NULL, 'Good', '2026-10-01 11:45:35', NULL, NULL, 3, '2026-10-01 02:52:51', '2026-10-01 03:45:35'),
(8, 'FG-INC-20261001-4FB90D39', 8, 'medium', 'assigned', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, '2026-10-01 09:15:40', '2026-10-01 09:17:21');

-- --------------------------------------------------------

--
-- Table structure for table `flood_reports`
--

CREATE TABLE `flood_reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `report_number` varchar(30) NOT NULL,
  `reporter_user_id` bigint(20) UNSIGNED NOT NULL,
  `reporter_name_snapshot` varchar(150) NOT NULL,
  `reporter_phone_snapshot` varchar(30) NOT NULL,
  `location_description` varchar(500) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `flood_description` text NOT NULL,
  `immediate_danger` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('submitted','under_review','correction_requested','resubmitted','rejected','approved','cancelled') NOT NULL DEFAULT 'submitted',
  `submitted_at` datetime NOT NULL,
  `reviewed_by` bigint(20) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `decision_reason` varchar(1000) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flood_reports`
--

INSERT INTO `flood_reports` (`id`, `report_number`, `reporter_user_id`, `reporter_name_snapshot`, `reporter_phone_snapshot`, `location_description`, `latitude`, `longitude`, `flood_description`, `immediate_danger`, `status`, `submitted_at`, `reviewed_by`, `reviewed_at`, `decision_reason`, `created_at`, `updated_at`) VALUES
(1, 'FG-RPT-20260908-C55BBD71', 2, 'FloodGuard Test Resident', '+639171234567', 'Controlled API test only - Barangay San Isidro', 14.7310000, 121.1450000, 'Controlled test report', 0, 'approved', '2026-09-08 12:52:41', 3, '2026-09-08 13:25:50', NULL, '2026-09-08 04:52:41', '2026-09-08 05:25:50'),
(2, 'FG-RPT-20260920-EEF82D07', 2, 'FloodGuard Test Resident', '+639171234567', 'Spillway Bridge', 37.4219983, -122.0840000, 'Controlled mobile application report test only.', 0, 'approved', '2026-09-20 15:45:57', 3, '2026-09-20 15:50:29', NULL, '2026-09-20 07:45:57', '2026-09-20 07:50:29'),
(3, 'FG-RPT-20260920-22BBB6AC', 2, 'FloodGuard Test Resident', '+639171234567', 'Spillway Bridge', 37.4219983, -122.0840000, 'Controlled Phase 13E live-location tracking test.', 0, 'approved', '2026-09-20 22:41:36', 3, '2026-09-20 22:43:06', NULL, '2026-09-20 14:41:36', '2026-09-20 14:43:06'),
(4, 'FG-RPT-20260921-84D8EB5F', 2, 'FloodGuard Test Resident', '+639171234567', 'Spillway', 37.4219983, -122.0840000, 'Medium', 0, 'approved', '2026-09-21 16:46:08', 3, '2026-09-21 16:53:28', NULL, '2026-09-21 08:46:08', '2026-09-21 08:53:28'),
(5, 'FG-RPT-20260926-256335FB', 7, 'Jec Antonio', '+639561347142', 'Eastwood Greenview Phase 2 Block 11 Lot 2', 14.7415753, 121.1638432, 'Critical', 1, 'approved', '2026-09-26 08:35:39', 3, '2026-09-26 08:36:17', NULL, '2026-09-26 08:35:39', '2026-09-26 08:36:17'),
(6, 'FG-RPT-20260930-54C8401B', 7, 'Jec Antonio', '+639561347142', 'Eastwood Greenview Phase', 14.7416788, 121.1637905, 'High', 0, 'approved', '2026-09-30 16:40:57', 3, '2026-09-30 17:09:12', NULL, '2026-09-30 08:40:57', '2026-09-30 09:09:12'),
(7, 'FG-RPT-20261001-EB55CC81', 12, 'Shemiel Asi', '+639999385385', 'Eastwood Greenview Phase 2 Block 11 Lot 2', 14.7416791, 121.1637850, 'Danger', 1, 'approved', '2026-10-01 10:50:58', 3, '2026-10-01 10:52:51', NULL, '2026-10-01 02:50:58', '2026-10-01 02:52:51'),
(8, 'FG-RPT-20261001-16045EBF', 13, 'Mark Owen', '+639958172602', 'spillway', 14.7333351, 121.0601384, 'severe', 1, 'approved', '2026-10-01 17:14:52', 3, '2026-10-01 17:15:40', NULL, '2026-10-01 09:14:52', '2026-10-01 09:15:40');

-- --------------------------------------------------------

--
-- Table structure for table `flood_report_photos`
--

CREATE TABLE `flood_report_photos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `flood_report_id` bigint(20) UNSIGNED NOT NULL,
  `storage_path` varchar(500) NOT NULL,
  `original_name` varchar(255) DEFAULT NULL,
  `mime_type` enum('image/jpeg','image/png','image/webp') NOT NULL,
  `file_size_bytes` int(10) UNSIGNED NOT NULL,
  `sha256_hash` char(64) NOT NULL,
  `uploaded_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flood_report_photos`
--

INSERT INTO `flood_report_photos` (`id`, `flood_report_id`, `storage_path`, `original_name`, `mime_type`, `file_size_bytes`, `sha256_hash`, `uploaded_by`, `created_at`) VALUES
(1, 1, 'storage/private/report_photos/54f71f918c3307f64e84c9b2c84c7cd4ecf60572e912fc47.png', 'floodguard-logo.png', 'image/png', 167440, '6cba97f77c37bc7d3937424333885c0d47df45370cab07920617776769d3eebb', 2, '2026-09-08 04:52:41'),
(2, 2, 'storage/private/report_photos/b21903d86b0d5cecfb03ba92385c5e3a87b6278f69089c04.jpg', 'scaled_bc5a45be-7233-4c23-8657-1faa323f12157627122248519611215.jpg', 'image/jpeg', 27115, 'a996aafc1943707cde91d22c2180c3a636c36ef3457554f20ea8b52e21e30242', 2, '2026-09-20 07:45:57'),
(3, 3, 'storage/private/report_photos/da6c2fc2069df63d0ea56f7c4f995e2ea2626a02262e9f99.jpg', 'scaled_ffd458ff-0ba3-4361-b75f-ee0d9a1375506081150814220587881.jpg', 'image/jpeg', 27244, 'ae1a7edf72b14cdf4369f35ba2c331e1fa378f7e03bd2a0348dc9669762f1b32', 2, '2026-09-20 14:41:36'),
(4, 4, 'storage/private/report_photos/1f397e33da42e88180632d2d63174addd0d63b471a147fe6.jpg', 'scaled_956974af-25b5-4cc3-9077-7b9e92da75e04996437531567856787.jpg', 'image/jpeg', 26810, '458ef7393372f189bc49ef5cc38f1a3233e30dea9b87e51a6b9bbb72cce2f435', 2, '2026-09-21 08:46:08'),
(5, 5, 'storage/private/report_photos/66a4eb87319a56da58e2e3d6a8aa4c75bcede4894192189b.jpg', 'scaled_6971.jpg', 'image/jpeg', 423577, 'e0ec281fd970a74b37d80d1f9c0ee09cd460f7541424d3ca094706a6b8f00e07', 7, '2026-09-26 08:35:39'),
(6, 6, 'storage/private/report_photos/1e20737c48a1361d0ddffaa4fb664e7251a97da6036d35ae.jpg', 'scaled_6969.jpg', 'image/jpeg', 629801, 'c015b0da4a45045e1ac5d406b334173ab6f1c1fe078357c3bedd5f4f82f69a85', 7, '2026-09-30 08:40:57'),
(7, 7, 'storage/private/report_photos/9d22a40c02a2476511bb29e1c6450ddc4898faff074be475.jpg', 'scaled_5567ed29-5d78-4017-ad7e-84c89d23ef388828147781623509275.jpg', 'image/jpeg', 463448, '593614b0413b64229300107abf9d7181e860e096bc7b915fb5e17fdc74333158', 12, '2026-10-01 02:50:58'),
(8, 8, 'storage/private/report_photos/df901070b8a7f124c27b54ac138265f21a80975143ab2533.jpg', 'scaled_a75a9236-b201-4aea-bf04-72564bbc6d5a774949584652275182.jpg', 'image/jpeg', 316840, '872dfde7e4bb168bd6adfb3e708afa8231a3479b43cf2f686f491ce9816fa60e', 13, '2026-10-01 09:14:52');

-- --------------------------------------------------------

--
-- Table structure for table `flood_report_revisions`
--

CREATE TABLE `flood_report_revisions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `flood_report_id` bigint(20) UNSIGNED NOT NULL,
  `revision_number` smallint(5) UNSIGNED NOT NULL,
  `location_description` varchar(500) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `flood_description` text NOT NULL,
  `immediate_danger` tinyint(1) NOT NULL,
  `submitted_by` bigint(20) UNSIGNED NOT NULL,
  `submitted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flood_report_revisions`
--

INSERT INTO `flood_report_revisions` (`id`, `flood_report_id`, `revision_number`, `location_description`, `latitude`, `longitude`, `flood_description`, `immediate_danger`, `submitted_by`, `submitted_at`) VALUES
(1, 1, 1, 'Controlled API test only - Barangay San Isidro', 14.7310000, 121.1450000, 'Controlled test report', 0, 2, '2026-09-08 12:52:41'),
(2, 2, 1, 'Spillway Bridge', 37.4219983, -122.0840000, 'Controlled mobile application report test only.', 0, 2, '2026-09-20 15:45:57'),
(3, 3, 1, 'Spillway Bridge', 37.4219983, -122.0840000, 'Controlled Phase 13E live-location tracking test.', 0, 2, '2026-09-20 22:41:36'),
(4, 4, 1, 'Spillway', 37.4219983, -122.0840000, 'Medium', 0, 2, '2026-09-21 16:46:08'),
(5, 5, 1, 'Eastwood Greenview Phase 2 Block 11 Lot 2', 14.7415753, 121.1638432, 'Critical', 1, 7, '2026-09-26 08:35:39'),
(6, 6, 1, 'Eastwood Greenview Phase', 14.7416788, 121.1637905, 'High', 0, 7, '2026-09-30 16:40:57'),
(7, 7, 1, 'Eastwood Greenview Phase 2 Block 11 Lot 2', 14.7416791, 121.1637850, 'Danger', 1, 12, '2026-10-01 10:50:58'),
(8, 8, 1, 'spillway', 14.7333351, 121.0601384, 'severe', 1, 13, '2026-10-01 17:14:52');

-- --------------------------------------------------------

--
-- Table structure for table `flood_report_status_history`
--

CREATE TABLE `flood_report_status_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `flood_report_id` bigint(20) UNSIGNED NOT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `reason` varchar(1000) DEFAULT NULL,
  `changed_by` bigint(20) UNSIGNED NOT NULL,
  `changed_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flood_report_status_history`
--

INSERT INTO `flood_report_status_history` (`id`, `flood_report_id`, `from_status`, `to_status`, `reason`, `changed_by`, `changed_at`) VALUES
(1, 1, NULL, 'submitted', NULL, 2, '2026-09-08 12:52:41'),
(2, 1, 'submitted', 'under_review', NULL, 3, '2026-09-08 13:23:30'),
(3, 1, 'under_review', 'approved', NULL, 3, '2026-09-08 13:25:50'),
(4, 2, NULL, 'submitted', NULL, 2, '2026-09-20 15:45:57'),
(5, 2, 'submitted', 'under_review', NULL, 3, '2026-09-20 15:49:51'),
(6, 2, 'under_review', 'approved', NULL, 3, '2026-09-20 15:50:29'),
(7, 3, NULL, 'submitted', NULL, 2, '2026-09-20 22:41:36'),
(8, 3, 'submitted', 'under_review', NULL, 3, '2026-09-20 22:41:59'),
(9, 3, 'under_review', 'approved', NULL, 3, '2026-09-20 22:43:06'),
(10, 4, NULL, 'submitted', NULL, 2, '2026-09-21 16:46:08'),
(11, 4, 'submitted', 'approved', NULL, 3, '2026-09-21 16:53:28'),
(12, 5, NULL, 'submitted', NULL, 7, '2026-09-26 08:35:39'),
(13, 5, 'submitted', 'approved', NULL, 3, '2026-09-26 08:36:17'),
(14, 6, NULL, 'submitted', NULL, 7, '2026-09-30 16:40:57'),
(15, 6, 'submitted', 'approved', NULL, 3, '2026-09-30 17:09:12'),
(16, 7, NULL, 'submitted', NULL, 12, '2026-10-01 10:50:58'),
(17, 7, 'submitted', 'approved', NULL, 3, '2026-10-01 10:52:51'),
(18, 8, NULL, 'submitted', NULL, 13, '2026-10-01 17:14:52'),
(19, 8, 'submitted', 'approved', NULL, 3, '2026-10-01 17:15:40');

-- --------------------------------------------------------

--
-- Table structure for table `incident_assignments`
--

CREATE TABLE `incident_assignments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `flood_incident_id` bigint(20) UNSIGNED NOT NULL,
  `response_team_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('assigned','accepted','declined','en_route','on_scene','response_in_progress','completed','cancelled') NOT NULL DEFAULT 'assigned',
  `assigned_by` bigint(20) UNSIGNED NOT NULL,
  `assigned_at` datetime NOT NULL,
  `accepted_by` bigint(20) UNSIGNED DEFAULT NULL,
  `accepted_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `incident_assignments`
--

INSERT INTO `incident_assignments` (`id`, `flood_incident_id`, `response_team_id`, `status`, `assigned_by`, `assigned_at`, `accepted_by`, `accepted_at`, `completed_at`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'completed', 3, '2026-09-09 09:22:05', 5, '2026-09-09 09:27:45', '2026-09-09 09:33:11', 'Controlled test completed. The area was assessed and no real emergency occurred.', '2026-09-09 01:22:05', '2026-09-09 01:33:11'),
(2, 2, 1, 'completed', 3, '2026-09-20 16:19:31', 5, '2026-09-20 16:22:24', '2026-09-20 16:29:26', 'Test response completed. Area inspected and the reported flood condition was verified. No immediate danger remains.', '2026-09-20 08:19:31', '2026-09-20 08:29:26'),
(3, 3, 1, 'completed', 3, '2026-09-20 22:44:17', 5, '2026-09-20 22:44:55', '2026-09-21 17:01:28', 'all good', '2026-09-20 14:44:17', '2026-09-21 09:01:28'),
(4, 4, 1, 'completed', 3, '2026-09-23 15:19:36', 5, '2026-09-23 15:20:38', '2026-09-23 15:22:38', 'ok', '2026-09-23 07:19:36', '2026-09-23 07:22:38'),
(5, 5, 1, 'completed', 3, '2026-09-26 08:36:24', 5, '2026-09-26 08:59:49', '2026-09-26 09:10:12', 'Good', '2026-09-26 08:36:24', '2026-09-26 09:10:12'),
(6, 6, 1, 'accepted', 3, '2026-09-30 17:09:37', 5, '2026-09-30 17:10:21', NULL, NULL, '2026-09-30 09:09:37', '2026-09-30 09:10:21'),
(7, 7, 2, 'completed', 3, '2026-10-01 10:52:59', 11, '2026-10-01 10:53:07', '2026-10-01 11:45:35', 'Good', '2026-10-01 02:52:59', '2026-10-01 03:45:35'),
(8, 8, 2, 'assigned', 3, '2026-10-01 17:17:21', NULL, NULL, NULL, NULL, '2026-10-01 09:17:21', '2026-10-01 09:17:21');

-- --------------------------------------------------------

--
-- Table structure for table `incident_status_history`
--

CREATE TABLE `incident_status_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `flood_incident_id` bigint(20) UNSIGNED NOT NULL,
  `assignment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `changed_by` bigint(20) UNSIGNED NOT NULL,
  `changed_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `incident_status_history`
--

INSERT INTO `incident_status_history` (`id`, `flood_incident_id`, `assignment_id`, `from_status`, `to_status`, `notes`, `changed_by`, `changed_at`) VALUES
(1, 1, NULL, NULL, 'awaiting_assignment', 'Created from approved resident report', 3, '2026-09-08 13:25:50'),
(2, 1, 1, 'awaiting_assignment', 'assigned', 'Proceed to the reported location and verify the flood condition. Observe safety precautions and provide status updates.', 3, '2026-09-09 09:22:05'),
(3, 1, 1, 'assigned', 'accepted', NULL, 5, '2026-09-09 09:27:45'),
(4, 1, 1, 'accepted', 'en_route', 'Responder team is traveling to the reported location.', 5, '2026-09-09 09:29:29'),
(5, 1, 1, 'en_route', 'on_scene', 'Responder team has arrived at the reported location.', 5, '2026-09-09 09:31:09'),
(6, 1, 1, 'on_scene', 'response_in_progress', 'Responder team is assessing the area and assisting affected residents.', 5, '2026-09-09 09:31:51'),
(7, 1, 1, 'response_in_progress', 'resolved', 'Controlled test completed. The area was assessed and no real emergency occurred.', 5, '2026-09-09 09:33:11'),
(8, 2, NULL, NULL, 'awaiting_assignment', 'Created from approved resident report', 3, '2026-09-20 15:50:29'),
(9, 2, 2, 'awaiting_assignment', 'assigned', NULL, 3, '2026-09-20 16:19:31'),
(10, 2, 2, 'assigned', 'accepted', NULL, 5, '2026-09-20 16:22:24'),
(11, 2, 2, 'accepted', 'en_route', NULL, 5, '2026-09-20 16:24:56'),
(12, 2, 2, 'en_route', 'on_scene', NULL, 5, '2026-09-20 16:27:11'),
(13, 2, 2, 'on_scene', 'response_in_progress', NULL, 5, '2026-09-20 16:28:02'),
(14, 2, 2, 'response_in_progress', 'resolved', 'Test response completed. Area inspected and the reported flood condition was verified. No immediate danger remains.', 5, '2026-09-20 16:29:26'),
(15, 3, NULL, NULL, 'awaiting_assignment', 'Created from approved resident report', 3, '2026-09-20 22:43:06'),
(16, 3, 3, 'awaiting_assignment', 'assigned', NULL, 3, '2026-09-20 22:44:17'),
(17, 3, 3, 'assigned', 'accepted', NULL, 5, '2026-09-20 22:44:55'),
(18, 4, NULL, NULL, 'awaiting_assignment', 'Created from verified resident report', 3, '2026-09-21 16:53:28'),
(19, 3, 3, 'accepted', 'en_route', NULL, 5, '2026-09-21 16:55:23'),
(20, 3, 3, 'en_route', 'on_scene', NULL, 5, '2026-09-21 16:55:29'),
(21, 3, 3, 'on_scene', 'response_in_progress', NULL, 5, '2026-09-21 16:55:32'),
(22, 3, 3, 'response_in_progress', 'resolved', 'all good', 5, '2026-09-21 17:01:28'),
(23, 4, 4, 'awaiting_assignment', 'assigned', NULL, 3, '2026-09-23 15:19:36'),
(24, 4, 4, 'assigned', 'accepted', NULL, 5, '2026-09-23 15:20:38'),
(25, 4, 4, 'accepted', 'en_route', NULL, 5, '2026-09-23 15:20:58'),
(26, 4, 4, 'en_route', 'on_scene', NULL, 5, '2026-09-23 15:22:08'),
(27, 4, 4, 'on_scene', 'resolved', 'ok', 5, '2026-09-23 15:22:38'),
(28, 5, NULL, NULL, 'awaiting_assignment', 'Created from verified resident report', 3, '2026-09-26 08:36:17'),
(29, 5, 5, 'awaiting_assignment', 'assigned', NULL, 3, '2026-09-26 08:36:24'),
(30, 5, 5, 'assigned', 'accepted', NULL, 5, '2026-09-26 08:59:49'),
(31, 5, 5, 'accepted', 'en_route', NULL, 5, '2026-09-26 09:05:44'),
(32, 5, 5, 'en_route', 'on_scene', NULL, 5, '2026-09-26 09:10:02'),
(33, 5, 5, 'on_scene', 'resolved', 'Good', 5, '2026-09-26 09:10:12'),
(34, 6, NULL, NULL, 'awaiting_assignment', 'Created from verified resident report', 3, '2026-09-30 17:09:12'),
(35, 6, 6, 'awaiting_assignment', 'assigned', NULL, 3, '2026-09-30 17:09:37'),
(36, 6, 6, 'assigned', 'accepted', NULL, 5, '2026-09-30 17:10:21'),
(37, 7, NULL, NULL, 'awaiting_assignment', 'Created from verified resident report', 3, '2026-10-01 10:52:51'),
(38, 7, 7, 'awaiting_assignment', 'assigned', NULL, 3, '2026-10-01 10:52:59'),
(39, 7, 7, 'assigned', 'accepted', NULL, 11, '2026-10-01 10:53:07'),
(40, 7, 7, 'accepted', 'en_route', NULL, 11, '2026-10-01 10:53:11'),
(41, 7, 7, 'en_route', 'on_scene', NULL, 11, '2026-10-01 10:53:13'),
(42, 7, 7, 'on_scene', 'resolved', 'Good', 11, '2026-10-01 11:45:35'),
(43, 8, NULL, NULL, 'awaiting_assignment', 'Created from verified resident report', 3, '2026-10-01 17:15:40'),
(44, 8, 8, 'awaiting_assignment', 'assigned', NULL, 3, '2026-10-01 17:17:21');

-- --------------------------------------------------------

--
-- Table structure for table `monitoring_devices`
--

CREATE TABLE `monitoring_devices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `device_uid` varchar(50) NOT NULL,
  `station_name` varchar(150) NOT NULL,
  `location_description` varchar(255) NOT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `api_key_hash` char(64) DEFAULT NULL,
  `operational_status` enum('never_connected','online','offline','maintenance','disabled') NOT NULL DEFAULT 'never_connected',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `firmware_version` varchar(50) DEFAULT NULL,
  `last_seen_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `monitoring_devices`
--

INSERT INTO `monitoring_devices` (`id`, `device_uid`, `station_name`, `location_description`, `latitude`, `longitude`, `api_key_hash`, `operational_status`, `is_active`, `firmware_version`, `last_seen_at`, `created_at`, `updated_at`) VALUES
(1, 'FG-STATION-001', 'Spillway Bridge Monitoring Station', 'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal', NULL, NULL, '2bd1216d3f300a162713d9718cbabb529c968d370d5cbef010685f7219336929', 'online', 1, 'FLOODGUARD-V8-INTEGRATED', '2026-10-01 17:27:25', '2026-09-08 03:14:20', '2026-10-01 09:27:25');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `password_reset_tokens`
--

INSERT INTO `password_reset_tokens` (`id`, `user_id`, `token_hash`, `expires_at`, `used_at`, `created_at`) VALUES
(1, 6, 'f0e950c1a4698cc4d02af7ab5bac0760cd9b3ebcd5e3f2b2e80e0c3a29d6b943', '2026-09-24 17:29:22', NULL, '2026-09-24 08:59:22'),
(2, 7, '151503588d13563aa7ee26ea95d8dc09e399fb20154a235ac9dd19bcdecf802a', '2026-09-25 12:40:53', '2026-09-25 12:35:41', '2026-09-25 04:25:53'),
(3, 7, '307bd09c0f302b718d5521b3b238ac33cf1bc5d3971152af85f9f761799e2f47', '2026-09-25 12:50:41', '2026-09-25 12:37:27', '2026-09-25 04:35:41'),
(4, 7, '93313633add10988927d1964e0f7f501a4c5a7b832d781529c36203fd8badeff', '2026-09-25 12:52:27', '2026-09-25 12:57:26', '2026-09-25 04:37:27'),
(5, 7, '897b49115879c742792c231701b2b4d0f0b81c2482af0b3dfe03c07efa82b189', '2026-09-25 13:12:26', '2026-09-25 12:58:32', '2026-09-25 04:57:26'),
(6, 7, '1939f184099c92b1c4e8791ff45010e62d55c35f93ee0b658b7de207dc522506', '2026-09-25 13:08:32', '2026-09-25 15:54:19', '2026-09-25 04:58:32'),
(7, 12, '4ffdd0490e61fb8b334b5c5246f1bcaf0431fc7dccc1ef3a46fccb63b5f87916', '2026-10-01 11:00:42', '2026-10-01 10:46:02', '2026-10-01 02:45:42'),
(8, 12, 'cd85d06f2c31ddb735f190706fbded9748ab2cc6447c0ff85575eb9080d4e27e', '2026-10-01 10:56:02', '2026-10-01 10:46:17', '2026-10-01 02:46:02');

-- --------------------------------------------------------

--
-- Table structure for table `pending_phone_verifications`
--

CREATE TABLE `pending_phone_verifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `verification_token` char(64) NOT NULL,
  `existing_resident_id` bigint(20) UNSIGNED DEFAULT NULL,
  `applicant_type` enum('resident','non_resident') NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `mobile_number` varchar(11) NOT NULL,
  `complete_address` varchar(255) NOT NULL,
  `purok_sitio` varchar(100) DEFAULT NULL,
  `barangay` varchar(100) NOT NULL,
  `municipality` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL DEFAULT 'Rizal',
  `bridge_connection` enum('resident_near_bridge','work','school','business','delivery_transportation','visiting_relatives','regular_commute','other') DEFAULT NULL,
  `bridge_connection_other` varchar(150) DEFAULT NULL,
  `bridge_use_frequency` enum('daily','several_times_week','weekly','occasionally') DEFAULT NULL,
  `proof_original_name` varchar(255) DEFAULT NULL,
  `proof_stored_name` varchar(255) DEFAULT NULL,
  `proof_mime_type` varchar(100) DEFAULT NULL,
  `proof_file_size` int(10) UNSIGNED DEFAULT NULL,
  `notification_scope` enum('full_community_alerts','bridge_alerts_only') NOT NULL,
  `sms_consent` tinyint(1) NOT NULL DEFAULT 1,
  `privacy_consent` tinyint(1) NOT NULL DEFAULT 1,
  `otp_hash` varchar(255) NOT NULL,
  `otp_expires_at` datetime NOT NULL,
  `otp_attempt_count` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `resend_count` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `last_sent_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--

CREATE TABLE `permissions` (
  `id` smallint(5) UNSIGNED NOT NULL,
  `slug` varchar(100) NOT NULL,
  `name` varchar(150) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `permissions`
--

INSERT INTO `permissions` (`id`, `slug`, `name`, `description`, `created_at`) VALUES
(1, 'profile.manage_own', 'Manage own profile', NULL, '2026-09-08 02:02:37'),
(2, 'monitoring.view', 'View monitoring information', NULL, '2026-09-08 02:02:37'),
(3, 'reports.create_own', 'Create own flood report', NULL, '2026-09-08 02:02:37'),
(4, 'reports.view_own', 'View own flood reports', NULL, '2026-09-08 02:02:37'),
(5, 'reports.review', 'Review resident flood reports', NULL, '2026-09-08 02:02:37'),
(6, 'reports.decide', 'Approve, reject, or request report correction', NULL, '2026-09-08 02:02:37'),
(7, 'incidents.manage_priority', 'Manage incident priority', NULL, '2026-09-08 02:02:37'),
(8, 'incidents.publish', 'Approve incident information for public display', NULL, '2026-09-08 02:02:37'),
(9, 'incidents.verify_resolution', 'Verify incident resolution', NULL, '2026-09-08 02:02:37'),
(10, 'assignments.manage', 'Create and manage responder assignments', NULL, '2026-09-08 02:02:37'),
(11, 'assignments.view_own', 'View own responder assignments', NULL, '2026-09-08 02:02:37'),
(12, 'assignments.update_own', 'Update own responder assignments', NULL, '2026-09-08 02:02:37'),
(13, 'locations.share_incident', 'Share location during an active incident', NULL, '2026-09-08 02:02:37'),
(14, 'locations.view_incident', 'View authorized incident locations', NULL, '2026-09-08 02:02:37'),
(15, 'device_commands.issue', 'Issue authorized device commands', NULL, '2026-09-08 02:02:37'),
(16, 'users.manage', 'Manage user accounts', NULL, '2026-09-08 02:02:37'),
(17, 'roles.manage', 'Manage roles and permissions', NULL, '2026-09-08 02:02:37'),
(18, 'devices.manage', 'Manage monitoring devices', NULL, '2026-09-08 02:02:37'),
(19, 'settings.manage', 'Manage system settings', NULL, '2026-09-08 02:02:37'),
(20, 'maintenance.manage', 'Manage maintenance records', NULL, '2026-09-08 02:02:37'),
(21, 'audit.view', 'View system audit records', NULL, '2026-09-08 02:02:37'),
(22, 'system_health.view', 'View system health', NULL, '2026-09-08 02:02:37'),
(23, 'posts.create_own', 'Create own community posts', NULL, '2026-09-20 15:14:10'),
(24, 'posts.view_own', 'View own community posts', NULL, '2026-09-20 15:14:10'),
(25, 'posts.review', 'Review resident community posts', NULL, '2026-09-20 15:14:10'),
(26, 'posts.decide', 'Approve, reject, or request revision of community posts', NULL, '2026-09-20 15:14:10');

-- --------------------------------------------------------

--
-- Table structure for table `push_notifications`
--

CREATE TABLE `push_notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `event_type` varchar(50) NOT NULL,
  `alert_level` enum('normal','warning','critical') NOT NULL,
  `title` varchar(150) NOT NULL,
  `body` varchar(1000) NOT NULL,
  `data_json` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `push_notifications`
--

INSERT INTO `push_notifications` (`id`, `event_type`, `alert_level`, `title`, `body`, `data_json`, `created_at`) VALUES
(1, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":10,\"measured_at\":\"2026-09-10T13:50:12+08:00\"}', '2026-09-10 05:50:12'),
(2, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":16,\"measured_at\":\"2026-09-20T10:47:50+08:00\"}', '2026-09-20 02:47:50'),
(3, 'manual_test', 'warning', 'FloodGuard Test Notification', 'This is a software notification test. No hardware or SMS was activated.', '{\"test\":true,\"source\":\"phpmyadmin\"}', '2026-09-28 15:19:26'),
(4, 'manual_test', 'warning', 'FloodGuard Warning Test', 'This is a test of the FloodGuard warning notification.', '{\"test\":true,\"alert_level\":\"warning\"}', '2026-09-28 11:36:48'),
(5, 'manual_test', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near Spillway Bridge. Avoid the area and follow official barangay instructions immediately.', '{\"test\":true,\"alert_level\":\"critical\"}', '2026-09-28 11:40:10'),
(6, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":30,\"measured_at\":\"2026-09-28T20:01:12+08:00\"}', '2026-09-28 12:01:12'),
(7, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-09-28T20:02:49+08:00\"}', '2026-09-28 12:02:49'),
(8, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":22.9,\"measured_at\":\"2026-10-01T02:50:35+08:00\"}', '2026-09-30 18:50:35'),
(9, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T02:51:00+08:00\"}', '2026-09-30 18:51:00'),
(10, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T11:12:26+08:00\"}', '2026-10-01 03:12:26'),
(11, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T11:14:56+08:00\"}', '2026-10-01 03:14:56'),
(12, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":5.3,\"measured_at\":\"2026-10-01T11:19:47+08:00\"}', '2026-10-01 03:19:47'),
(13, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":23,\"measured_at\":\"2026-10-01T11:22:39+08:00\"}', '2026-10-01 03:22:39'),
(14, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":8,\"measured_at\":\"2026-10-01T11:23:18+08:00\"}', '2026-10-01 03:23:18'),
(15, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":8.2,\"measured_at\":\"2026-10-01T11:29:12+08:00\"}', '2026-10-01 03:29:12'),
(16, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":22.9,\"measured_at\":\"2026-10-01T11:29:22+08:00\"}', '2026-10-01 03:29:22'),
(17, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":8.2,\"measured_at\":\"2026-10-01T11:29:55+08:00\"}', '2026-10-01 03:29:55'),
(18, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":22.7,\"measured_at\":\"2026-10-01T11:31:27+08:00\"}', '2026-10-01 03:31:27'),
(19, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":8.3,\"measured_at\":\"2026-10-01T11:31:45+08:00\"}', '2026-10-01 03:31:45'),
(20, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T12:33:22+08:00\"}', '2026-10-01 04:33:22'),
(21, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T13:07:54+08:00\"}', '2026-10-01 05:07:54'),
(22, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T13:10:50+08:00\"}', '2026-10-01 05:10:50'),
(23, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":5.5,\"measured_at\":\"2026-10-01T15:56:22+08:00\"}', '2026-10-01 07:56:22'),
(24, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T15:57:01+08:00\"}', '2026-10-01 07:57:01'),
(25, 'alert_transition', 'critical', 'Critical Flood Alert', 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"critical\",\"water_level_cm\":16.5,\"measured_at\":\"2026-10-01T17:05:54+08:00\"}', '2026-10-01 09:05:54'),
(26, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":11.7,\"measured_at\":\"2026-10-01T17:06:04+08:00\"}', '2026-10-01 09:06:04'),
(27, 'alert_transition', 'normal', 'Flood Condition Cleared', 'The monitored flood condition has returned to Normal.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"normal\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T17:06:26+08:00\"}', '2026-10-01 09:06:26'),
(28, 'alert_transition', 'warning', 'Flood Warning', 'The Spillway Bridge monitoring station has detected a warning-level flood condition.', '{\"device_id\":\"FG-STATION-001\",\"alert_level\":\"warning\",\"water_level_cm\":0,\"measured_at\":\"2026-10-01T17:11:06+08:00\"}', '2026-10-01 09:11:06');

-- --------------------------------------------------------

--
-- Table structure for table `push_notification_recipients`
--

CREATE TABLE `push_notification_recipients` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `push_notification_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `delivery_status` enum('queued','sent','failed','skipped') NOT NULL DEFAULT 'queued',
  `attempt_count` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `provider_message_id` varchar(255) DEFAULT NULL,
  `last_error` varchar(500) DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `read_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `push_notification_recipients`
--

INSERT INTO `push_notification_recipients` (`id`, `push_notification_id`, `user_id`, `delivery_status`, `attempt_count`, `provider_message_id`, `last_error`, `sent_at`, `read_at`, `created_at`, `updated_at`) VALUES
(1, 2, 2, 'skipped', 0, NULL, 'Skipped during Firebase deployment because the alert was stale.', NULL, '2026-09-20 10:49:20', '2026-09-20 02:47:50', '2026-09-28 09:34:32'),
(2, 3, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790589182033858%1a4adb001a4adb00', NULL, '2026-09-28 17:53:02', '2026-09-28 15:30:03', '2026-09-28 15:29:15', '2026-09-28 09:53:02'),
(3, 4, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790595422540646%1a4adb001a4adb00', NULL, '2026-09-28 19:37:02', '2026-09-28 19:37:39', '2026-09-28 11:36:48', '2026-09-28 11:37:39'),
(4, 5, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790595662237491%1a4adb001a4adb00', NULL, '2026-09-28 19:41:02', '2026-09-28 19:41:26', '2026-09-28 11:40:10', '2026-09-28 11:41:26'),
(5, 6, 2, 'skipped', 2, NULL, 'No active push device.', NULL, NULL, '2026-09-28 12:01:12', '2026-09-28 12:03:02'),
(6, 6, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790596922398296%1a4adb001a4adb00', NULL, '2026-09-28 20:02:02', '2026-09-28 20:09:10', '2026-09-28 12:01:12', '2026-09-28 12:09:10'),
(8, 7, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790596982485510%1a4adb001a4adb00', NULL, '2026-09-28 20:03:02', '2026-09-28 20:09:15', '2026-09-28 12:02:49', '2026-09-28 12:09:15'),
(9, 8, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790794261889213%1a4adb001a4adb00', NULL, '2026-10-01 02:51:02', '2026-10-01 02:50:50', '2026-09-30 18:50:35', '2026-09-30 18:51:02'),
(10, 9, 7, 'sent', 1, 'projects/floodguard-73402/messages/0:1790794262336440%1a4adb001a4adb00', NULL, '2026-10-01 02:51:02', '2026-10-01 02:56:22', '2026-09-30 18:51:00', '2026-09-30 18:56:22'),
(11, 10, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790824382416782%1a4adb001a4adb00', NULL, '2026-10-01 11:13:02', '2026-10-01 11:20:28', '2026-10-01 03:12:26', '2026-10-01 03:20:28'),
(12, 11, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790824503813572%1a4adb001a4adb00', NULL, '2026-10-01 11:15:04', '2026-10-01 11:20:28', '2026-10-01 03:14:56', '2026-10-01 03:20:28'),
(13, 12, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790824802839568%1a4adb001a4adb00', NULL, '2026-10-01 11:20:02', '2026-10-01 11:20:28', '2026-10-01 03:19:47', '2026-10-01 03:20:28'),
(14, 13, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790824983141975%1a4adb001a4adb00', NULL, '2026-10-01 11:23:03', NULL, '2026-10-01 03:22:39', '2026-10-01 03:23:03'),
(15, 14, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825043457253%1a4adb001a4adb00', NULL, '2026-10-01 11:24:03', '2026-10-01 11:23:27', '2026-10-01 03:23:18', '2026-10-01 03:24:03'),
(16, 15, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825404191240%1a4adb001a4adb00', NULL, '2026-10-01 11:30:04', NULL, '2026-10-01 03:29:12', '2026-10-01 03:30:04'),
(17, 16, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825404341677%1a4adb001a4adb00', NULL, '2026-10-01 11:30:04', NULL, '2026-10-01 03:29:22', '2026-10-01 03:30:04'),
(18, 17, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825404438899%1a4adb001a4adb00', NULL, '2026-10-01 11:30:04', NULL, '2026-10-01 03:29:55', '2026-10-01 03:30:04'),
(19, 18, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825522850809%1a4adb001a4adb00', NULL, '2026-10-01 11:32:02', NULL, '2026-10-01 03:31:27', '2026-10-01 03:32:02'),
(20, 19, 12, 'sent', 1, 'projects/floodguard-73402/messages/0:1790825523153991%1a4adb001a4adb00', NULL, '2026-10-01 11:32:03', NULL, '2026-10-01 03:31:45', '2026-10-01 03:32:03'),
(21, 20, 12, 'skipped', 2, NULL, 'No active push device.', NULL, NULL, '2026-10-01 04:33:22', '2026-10-01 04:35:02'),
(22, 25, 13, 'sent', 1, 'projects/floodguard-73402/messages/0:1790845563079973%1a4adb001a4adb00', NULL, '2026-10-01 17:06:03', NULL, '2026-10-01 09:05:54', '2026-10-01 09:06:03'),
(23, 26, 13, 'sent', 1, 'projects/floodguard-73402/messages/0:1790845622163957%1a4adb001a4adb00', NULL, '2026-10-01 17:07:02', NULL, '2026-10-01 09:06:04', '2026-10-01 09:07:02'),
(24, 27, 13, 'sent', 1, 'projects/floodguard-73402/messages/0:1790845622424906%1a4adb001a4adb00', NULL, '2026-10-01 17:07:02', NULL, '2026-10-01 09:06:26', '2026-10-01 09:07:02'),
(25, 28, 13, 'sent', 1, 'projects/floodguard-73402/messages/0:1790845922203917%1a4adb001a4adb00', NULL, '2026-10-01 17:12:02', NULL, '2026-10-01 09:11:06', '2026-10-01 09:12:02');

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
--

CREATE TABLE `rate_limits` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `action_key` varchar(80) NOT NULL,
  `subject_hash` char(64) NOT NULL,
  `attempt_count` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `window_started_at` datetime NOT NULL,
  `blocked_until` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rate_limits`
--

INSERT INTO `rate_limits` (`id`, `action_key`, `subject_hash`, `attempt_count`, `window_started_at`, `blocked_until`, `updated_at`) VALUES
(3, 'admin_login', '547bb0d912f33a6a9424d2145d2b96e2ced87a9924f996da97082f9ae8f3de6d', 1, '2026-09-25 17:06:04', NULL, '2026-09-25 09:06:04'),
(6, 'password_reset', 'dbd8b13305c52b47d7a0e2d2111b1e233942e3e67fbb978782a517cfe49de4db', 1, '2026-09-24 16:59:22', '2026-09-24 17:00:22', '2026-09-24 08:59:22'),
(7, 'password_reset', '774f5251b9abff15edc453aa9e76d0a08087030e820289864186c6c4a759653b', 1, '2026-09-25 12:57:32', '2026-09-25 12:58:32', '2026-09-25 04:57:32'),
(9, 'resident_register', '59d2125a3328895d86134128ae6b6f5a8f7d61e855b9fc0a07e2947481dbb0cd', 3, '2026-09-25 13:30:34', NULL, '2026-09-25 05:35:57'),
(11, 'staff_login', '3e9b2351765e5538882ef31ad5c6c5520d7411dbb3b26920bad2529a6bff10c4', 1, '2026-09-25 17:04:21', NULL, '2026-09-25 09:04:21'),
(12, 'resident_login', '7854d48d954b0a02fcbacd6a9ddc3b073f37a7f606d8ff15ab0c13b15f0d1945', 2, '2026-09-25 10:53:37', NULL, '2026-09-25 10:54:06'),
(14, 'resident_login', '9d70dc72a8f6aced81f85677d378e2a72c7aba58db7ddf1d4a5a4d3b0fbce5ed', 1, '2026-09-28 14:21:06', NULL, '2026-09-28 06:21:06'),
(15, 'admin_login', 'f243f337657f40648b0a3abf11deebe9cd42879e308162dbcc4378c1f2451786', 1, '2026-09-28 15:00:30', NULL, '2026-09-28 07:00:30'),
(16, 'staff_login', 'aa2b65a0cfdda11fd32d57493e93eeeb7e4898d5c96120cb88ba833b5a75cadd', 1, '2026-09-30 22:15:39', NULL, '2026-09-30 14:15:39'),
(17, 'resident_login', '448982d23f878388b83fd895440d8da7631b1168a72b33c8fa9fef38b49badf7', 1, '2026-09-30 15:45:38', NULL, '2026-09-30 07:45:38'),
(18, 'staff_login', '22fbe80da88b4f44cd5bb33bdfc2ad8c335782ef44906fce951214c7375f9cbd', 1, '2026-09-30 17:07:56', NULL, '2026-09-30 09:07:56'),
(20, 'admin_login', '8311451feeae37d2457568fdfba47aad975f74f95ef8bcb16c0c6412fec81c16', 1, '2026-09-30 17:30:13', NULL, '2026-09-30 09:30:13'),
(22, 'password_reset', '8311451feeae37d2457568fdfba47aad975f74f95ef8bcb16c0c6412fec81c16', 1, '2026-10-01 10:45:45', '2026-10-01 10:46:45', '2026-10-01 02:45:45'),
(24, 'resident_register', '385da0c34943b20fc723106a1a88bc9b76eec67cf545be9d6d7023fa967e161a', 1, '2026-10-01 16:51:38', NULL, '2026-10-01 08:51:38'),
(27, 'staff_login', 'ec3f6e5d46a3b2e3683c39c87b636fc986b5dcf78c6df5786dcf143b16b260ef', 1, '2026-10-16 05:37:52', NULL, '2026-10-15 21:37:52'),
(28, 'admin_login', 'edd61c1e705c0fee41156a4679219578778a91bec3f6de53ee739e4f5e25c39d', 4, '2026-11-12 10:41:27', NULL, '2026-11-12 02:42:09');

-- --------------------------------------------------------

--
-- Table structure for table `registration_counters`
--

CREATE TABLE `registration_counters` (
  `applicant_type` enum('resident','non_resident') NOT NULL,
  `last_number` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `registration_counters`
--

INSERT INTO `registration_counters` (`applicant_type`, `last_number`, `updated_at`) VALUES
('resident', 5, '2026-08-25 23:41:42'),
('non_resident', 3, '2026-08-25 17:23:20');

-- --------------------------------------------------------

--
-- Table structure for table `residents`
--

CREATE TABLE `residents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reference_no` varchar(30) NOT NULL,
  `applicant_type` enum('resident','non_resident') NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `mobile_number` varchar(11) NOT NULL,
  `complete_address` varchar(255) DEFAULT NULL,
  `purok_sitio` varchar(100) DEFAULT NULL,
  `barangay` varchar(100) NOT NULL,
  `municipality` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL DEFAULT 'Rizal',
  `bridge_connection` enum('resident_near_bridge','work','school','business','delivery_transportation','visiting_relatives','regular_commute','other') DEFAULT NULL,
  `bridge_connection_other` varchar(150) DEFAULT NULL,
  `bridge_use_frequency` enum('daily','several_times_week','weekly','occasionally') DEFAULT NULL,
  `proof_original_name` varchar(255) DEFAULT NULL,
  `proof_stored_name` varchar(255) DEFAULT NULL,
  `proof_mime_type` varchar(100) DEFAULT NULL,
  `proof_file_size` int(10) UNSIGNED DEFAULT NULL,
  `notification_scope` enum('full_community_alerts','bridge_alerts_only') NOT NULL,
  `sms_consent` tinyint(1) NOT NULL DEFAULT 0,
  `privacy_consent` tinyint(1) NOT NULL DEFAULT 0,
  `mobile_verified` tinyint(1) NOT NULL DEFAULT 0,
  `registration_status` enum('pending','approved','rejected','suspended','unsubscribed') NOT NULL DEFAULT 'pending',
  `rejection_reason` text DEFAULT NULL,
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `residents`
--

INSERT INTO `residents` (`id`, `reference_no`, `applicant_type`, `full_name`, `mobile_number`, `complete_address`, `purok_sitio`, `barangay`, `municipality`, `province`, `bridge_connection`, `bridge_connection_other`, `bridge_use_frequency`, `proof_original_name`, `proof_stored_name`, `proof_mime_type`, `proof_file_size`, `notification_scope`, `sms_consent`, `privacy_consent`, `mobile_verified`, `registration_status`, `rejection_reason`, `reviewed_by`, `reviewed_at`, `created_at`, `updated_at`) VALUES
(4, 'NR0002', 'non_resident', 'Kipp Jene Bautista', '09494334497', '#69E. Rodriguez High-way', NULL, 'San Jose', 'Rodriguez', 'Rizal', 'visiting_relatives', NULL, 'daily', NULL, NULL, NULL, NULL, 'bridge_alerts_only', 1, 1, 1, 'approved', NULL, 2, '2026-08-20 14:32:41', '2026-08-20 06:29:14', '2026-08-20 06:32:41'),
(7, 'NR0003', 'non_resident', 'Jericho Castillo', '09561347142', 'B19 L14 sampaguita st.\r\nDolmar Golden Hills Subdivision, Brgy 167 Llano', NULL, 'San Isidro', 'Rodriguez', 'Rizal', 'work', NULL, 'several_times_week', NULL, NULL, NULL, NULL, 'bridge_alerts_only', 1, 1, 1, 'approved', NULL, 2, '2026-08-26 01:23:57', '2026-08-25 17:23:20', '2026-08-25 17:23:57'),
(8, 'R0005', 'resident', 'Gio Asi', '09999385385', 'B19 L14 sampaguita st.\r\nDolmar Golden Hills Subdivision, Brgy 167 Llano', NULL, 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, NULL, 'images.jpg', '20260826074124-05dd68eae2d1f2ab.jpg', 'image/jpeg', 47962, 'full_community_alerts', 1, 1, 1, 'approved', NULL, 2, '2026-08-26 07:42:12', '2026-08-25 23:41:42', '2026-08-25 23:42:12');

-- --------------------------------------------------------

--
-- Table structure for table `resident_location_sharing`
--

CREATE TABLE `resident_location_sharing` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `incident_assignment_id` bigint(20) UNSIGNED NOT NULL,
  `resident_user_id` bigint(20) UNSIGNED NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `consented_at` datetime DEFAULT NULL,
  `stopped_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resident_location_sharing`
--

INSERT INTO `resident_location_sharing` (`id`, `incident_assignment_id`, `resident_user_id`, `is_enabled`, `consented_at`, `stopped_at`, `created_at`, `updated_at`) VALUES
(1, 3, 2, 1, '2026-09-20 22:58:14', NULL, '2026-09-20 14:58:14', '2026-09-20 14:58:14'),
(2, 4, 2, 1, '2026-09-23 15:21:25', NULL, '2026-09-23 07:21:25', '2026-09-23 07:21:25'),
(3, 5, 7, 1, '2026-09-26 09:00:08', NULL, '2026-09-26 09:00:08', '2026-09-26 09:00:08'),
(4, 6, 7, 0, '2026-09-30 17:10:50', '2026-10-01 16:26:10', '2026-09-30 09:10:50', '2026-10-01 08:26:10'),
(5, 7, 12, 1, '2026-10-01 10:55:03', NULL, '2026-10-01 02:55:03', '2026-10-01 02:55:03');

-- --------------------------------------------------------

--
-- Table structure for table `resident_location_updates`
--

CREATE TABLE `resident_location_updates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `incident_assignment_id` bigint(20) UNSIGNED NOT NULL,
  `resident_user_id` bigint(20) UNSIGNED NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `accuracy_meters` decimal(8,2) DEFAULT NULL,
  `recorded_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resident_location_updates`
--

INSERT INTO `resident_location_updates` (`id`, `incident_assignment_id`, `resident_user_id`, `latitude`, `longitude`, `accuracy_meters`, `recorded_at`, `created_at`) VALUES
(1, 3, 2, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:58:19', '2026-09-20 14:58:19'),
(2, 3, 2, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:58:19', '2026-09-20 14:58:19'),
(3, 3, 2, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:58:19', '2026-09-20 14:58:19'),
(4, 3, 2, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:58:19', '2026-09-20 14:58:19'),
(5, 4, 2, 37.4219983, -122.0840000, 5.00, '2026-09-23 15:21:29', '2026-09-23 07:21:29'),
(6, 4, 2, 37.4219983, -122.0840000, 5.00, '2026-09-23 15:21:29', '2026-09-23 07:21:29'),
(7, 4, 2, 37.4219983, -122.0840000, 5.00, '2026-09-23 15:21:30', '2026-09-23 07:21:30'),
(8, 4, 2, 37.4219983, -122.0840000, 5.00, '2026-09-23 15:21:30', '2026-09-23 07:21:30'),
(9, 5, 7, 14.7416769, 121.1637920, 20.00, '2026-09-26 09:00:12', '2026-09-26 09:00:12'),
(10, 5, 7, 14.7416769, 121.1637920, 20.00, '2026-09-26 09:00:12', '2026-09-26 09:00:12'),
(11, 5, 7, 14.7416769, 121.1637920, 20.00, '2026-09-26 09:00:13', '2026-09-26 09:00:13'),
(12, 5, 7, 14.7416769, 121.1637920, 20.00, '2026-09-26 09:00:13', '2026-09-26 09:00:13'),
(13, 5, 7, 14.7416748, 121.1637930, 7.21, '2026-09-26 09:05:00', '2026-09-26 09:05:00'),
(14, 5, 7, 14.7416755, 121.1637935, 4.63, '2026-09-26 09:06:16', '2026-09-26 09:06:16'),
(15, 6, 7, 14.7416274, 121.1638229, 20.00, '2026-09-30 17:10:52', '2026-09-30 09:10:52'),
(16, 6, 7, 14.7416274, 121.1638229, 20.00, '2026-09-30 17:10:52', '2026-09-30 09:10:52'),
(17, 6, 7, 14.7416274, 121.1638229, 20.00, '2026-09-30 17:10:53', '2026-09-30 09:10:53'),
(18, 6, 7, 14.7416848, 121.1636911, 53.17, '2026-09-30 17:12:14', '2026-09-30 09:12:14'),
(19, 6, 7, 14.7416848, 121.1636911, 53.17, '2026-09-30 17:12:14', '2026-09-30 09:12:14'),
(20, 6, 7, 14.7416632, 121.1637907, 15.83, '2026-09-30 17:12:42', '2026-09-30 09:12:42'),
(21, 6, 7, 14.7416632, 121.1637907, 15.83, '2026-09-30 17:12:42', '2026-09-30 09:12:42'),
(22, 6, 7, 14.7416854, 121.1637800, 30.44, '2026-09-30 17:23:54', '2026-09-30 09:23:54'),
(23, 6, 7, 14.7446033, 121.1637008, 300.00, '2026-09-30 17:25:42', '2026-09-30 09:25:42'),
(24, 6, 7, 14.7416789, 121.1637905, 20.00, '2026-09-30 17:25:47', '2026-09-30 09:25:47'),
(25, 6, 7, 14.7416789, 121.1637905, 20.00, '2026-09-30 17:26:14', '2026-09-30 09:26:14'),
(26, 6, 7, 14.7416788, 121.1637905, 20.00, '2026-09-30 17:26:19', '2026-09-30 09:26:19'),
(27, 6, 7, 14.7446033, 121.1637008, 300.00, '2026-09-30 17:26:34', '2026-09-30 09:26:34'),
(28, 6, 7, 14.7416788, 121.1637905, 20.00, '2026-09-30 17:26:38', '2026-09-30 09:26:38'),
(29, 6, 7, 14.7416790, 121.1637912, 20.00, '2026-09-30 18:31:00', '2026-09-30 10:31:00'),
(30, 6, 7, 14.7416797, 121.1637942, 100.00, '2026-09-30 19:13:29', '2026-09-30 11:13:29'),
(31, 6, 7, 14.7416527, 121.1639022, 19.20, '2026-09-30 19:56:00', '2026-09-30 11:56:00'),
(32, 6, 7, 14.7416442, 121.1638095, 19.15, '2026-09-30 19:56:41', '2026-09-30 11:56:41'),
(33, 6, 7, 14.7417279, 121.1637653, 111.89, '2026-09-30 20:04:20', '2026-09-30 12:04:20'),
(34, 6, 7, 14.7416776, 121.1638431, 26.71, '2026-09-30 20:04:30', '2026-09-30 12:04:30'),
(35, 6, 7, 14.7416558, 121.1638144, 47.36, '2026-09-30 20:13:58', '2026-09-30 12:13:58'),
(36, 6, 7, 14.7415997, 121.1637751, 61.28, '2026-09-30 20:15:38', '2026-09-30 12:15:38'),
(37, 6, 7, 14.7446033, 121.1637008, 300.00, '2026-09-30 20:15:39', '2026-09-30 12:15:39'),
(38, 6, 7, 14.7416849, 121.1638241, 31.94, '2026-09-30 20:15:50', '2026-09-30 12:15:50'),
(39, 6, 7, 14.7416200, 121.1638925, 32.65, '2026-09-30 20:20:42', '2026-09-30 12:20:42'),
(40, 6, 7, 14.7416263, 121.1638222, 5.21, '2026-09-30 20:26:05', '2026-09-30 12:26:05'),
(41, 6, 7, 14.7416747, 121.1637853, 64.10, '2026-09-30 23:41:56', '2026-09-30 15:41:56'),
(42, 6, 7, 14.7416747, 121.1637853, 64.10, '2026-09-30 23:41:56', '2026-09-30 15:41:56'),
(43, 6, 7, 14.7416720, 121.1637773, 14.01, '2026-10-01 10:30:14', '2026-10-01 02:30:14'),
(44, 6, 7, 14.7416720, 121.1637773, 14.01, '2026-10-01 10:30:14', '2026-10-01 02:30:14'),
(45, 7, 12, 14.7416778, 121.1637907, 20.00, '2026-10-01 10:55:04', '2026-10-01 02:55:04'),
(46, 7, 12, 14.7416722, 121.1637323, 7.60, '2026-10-01 10:55:07', '2026-10-01 02:55:07'),
(47, 7, 12, 14.7416401, 121.1636398, 6.72, '2026-10-01 10:55:57', '2026-10-01 02:55:57'),
(48, 7, 12, 14.7416990, 121.1634596, 4.30, '2026-10-01 10:56:18', '2026-10-01 02:56:18'),
(49, 7, 12, 14.7417414, 121.1633746, 4.75, '2026-10-01 10:56:24', '2026-10-01 02:56:24'),
(50, 7, 12, 14.7417947, 121.1632958, 5.63, '2026-10-01 10:56:31', '2026-10-01 02:56:31'),
(51, 7, 12, 14.7418370, 121.1632106, 8.19, '2026-10-01 10:56:39', '2026-10-01 02:56:39'),
(52, 7, 12, 14.7419117, 121.1631562, 8.84, '2026-10-01 10:56:48', '2026-10-01 02:56:48'),
(53, 7, 12, 14.7419856, 121.1630981, 8.43, '2026-10-01 10:56:57', '2026-10-01 02:56:57'),
(54, 7, 12, 14.7420412, 121.1630223, 11.34, '2026-10-01 10:57:06', '2026-10-01 02:57:06'),
(55, 7, 12, 14.7421088, 121.1629584, 10.73, '2026-10-01 10:57:17', '2026-10-01 02:57:17'),
(56, 7, 12, 14.7422066, 121.1629478, 10.50, '2026-10-01 10:57:24', '2026-10-01 02:57:24'),
(57, 7, 12, 14.7421028, 121.1630039, 8.08, '2026-10-01 10:58:35', '2026-10-01 02:58:35'),
(58, 7, 12, 14.7418805, 121.1631078, 14.88, '2026-10-01 11:12:01', '2026-10-01 03:12:01'),
(59, 7, 12, 14.7416711, 121.1637894, 37.99, '2026-10-01 11:15:07', '2026-10-01 03:15:07'),
(60, 7, 12, 14.7446033, 121.1637008, 300.00, '2026-10-01 11:20:18', '2026-10-01 03:20:18'),
(61, 6, 7, 14.7333225, 121.0600878, 93.31, '2026-10-01 16:26:01', '2026-10-01 08:26:01'),
(62, 6, 7, 14.7333225, 121.0600878, 93.31, '2026-10-01 16:26:01', '2026-10-01 08:26:01'),
(63, 6, 7, 14.7333271, 121.0600948, 77.86, '2026-10-01 16:26:08', '2026-10-01 08:26:08'),
(64, 6, 7, 14.7333271, 121.0600948, 77.86, '2026-10-01 16:26:08', '2026-10-01 08:26:08');

-- --------------------------------------------------------

--
-- Table structure for table `resident_profiles`
--

CREATE TABLE `resident_profiles` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `mobile_number` varchar(20) NOT NULL,
  `address_line` varchar(500) NOT NULL,
  `verification_proof_path` varchar(500) DEFAULT NULL,
  `verification_proof_mime` varchar(100) DEFAULT NULL,
  `barangay` varchar(120) NOT NULL DEFAULT 'San Isidro',
  `city_municipality` varchar(120) NOT NULL DEFAULT 'Rodriguez',
  `province` varchar(120) NOT NULL DEFAULT 'Rizal',
  `emergency_contact_name` varchar(150) DEFAULT NULL,
  `emergency_contact_number` varchar(20) DEFAULT NULL,
  `push_notifications_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `notification_consented_at` datetime DEFAULT NULL,
  `location_sharing_consent` tinyint(1) NOT NULL DEFAULT 0,
  `approval_status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `reviewed_by` bigint(20) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `rejection_reason` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resident_profiles`
--

INSERT INTO `resident_profiles` (`user_id`, `mobile_number`, `address_line`, `verification_proof_path`, `verification_proof_mime`, `barangay`, `city_municipality`, `province`, `emergency_contact_name`, `emergency_contact_number`, `push_notifications_enabled`, `notification_consented_at`, `location_sharing_consent`, `approval_status`, `reviewed_by`, `reviewed_at`, `rejection_reason`, `created_at`, `updated_at`) VALUES
(2, '+639171234567', 'Barangay San Isidro, Rodriguez, Rizal', NULL, NULL, 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-09-08 12:45:26', 0, 'approved', NULL, '2026-09-24 16:53:36', NULL, '2026-09-08 04:45:26', '2026-09-24 08:53:36'),
(6, '+639494334497', '#69 RODRIGUEZ HGHWY RIZAL', 'resident_proofs/c28bc8804a08b4852adc6dc3f3d6da9252960a0b92977dd1.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-09-24 16:58:32', 0, 'approved', 1, '2026-09-24 16:58:48', NULL, '2026-09-24 08:58:32', '2026-09-24 08:58:48'),
(7, '+639561347142', 'B1 L1 Sampaguita St', 'resident_proofs/932f2c0879d9ec4e35c755ecb0ef19ad4aa5b8f52e361e8a.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-09-25 15:54:19', 0, 'approved', 1, '2026-09-25 15:55:05', NULL, '2026-09-25 07:54:19', '2026-09-25 07:55:05'),
(8, '+639561347352', 'B1 L1 Sampaguita St.', 'resident_proofs/5959d4732ca88791cfa3aad23828a626ae23f27df2cf6474.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-09-25 13:13:49', 0, 'pending', NULL, NULL, NULL, '2026-09-25 05:13:49', '2026-09-25 05:13:49'),
(9, '+639561348274', 'B1 L1 Sampaguita St. San Isidro', 'resident_proofs/9d243e452f5c8c3629f3320e6970acf18305a72a80fd157e.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-09-25 13:15:44', 0, 'rejected', 1, '2026-09-25 13:29:09', 'not resident', '2026-09-25 05:15:44', '2026-09-25 05:29:09'),
(12, '+639999385385', 'Eastwood Greenview Phase 2 Block 11 Lot 2', 'resident_proofs/aef651a15b7283a892c09ac300d31c458e6c8c67427ce32c.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-10-01 10:43:10', 0, 'approved', 1, '2026-10-01 10:45:39', NULL, '2026-10-01 02:43:10', '2026-10-01 02:45:39'),
(13, '+639958172602', 'Eastwood Greenview Phase 2 Block 11 Lot 2', 'resident_proofs/305639f1b3bf42814ae21667ae2ac98eefc0a4a3175d2cdd.jpg', 'image/jpeg', 'San Isidro', 'Rodriguez', 'Rizal', NULL, NULL, 1, '2026-10-01 16:52:55', 0, 'approved', 1, '2026-10-01 16:55:01', NULL, '2026-10-01 08:52:55', '2026-10-01 08:55:01');

-- --------------------------------------------------------

--
-- Table structure for table `resident_push_devices`
--

CREATE TABLE `resident_push_devices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `device_token` varchar(512) NOT NULL,
  `platform` enum('android','ios','web') NOT NULL,
  `device_name` varchar(150) DEFAULT NULL,
  `app_version` varchar(50) DEFAULT NULL,
  `last_seen_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `resident_push_devices`
--

INSERT INTO `resident_push_devices` (`id`, `user_id`, `token_hash`, `device_token`, `platform`, `device_name`, `app_version`, `last_seen_at`, `revoked_at`, `created_at`, `updated_at`) VALUES
(1, 2, '83bae644ca7f68725df39562db452e747e0ef2bba800bbb3891db685f47fe5f4', 'floodguard-test-android-4588b6bad669494ea78bd4470d884d49', 'android', 'FloodGuard Android Test', '0.1.0', '2026-09-20 10:45:57', '2026-09-28 20:02:02', '2026-09-20 02:45:57', '2026-09-28 12:02:02'),
(2, 7, 'f4e4c6e26d39e72d97fff564aea6fe8f5cec10b26a507efd90a539a0cc37f316', 'e-dpN1L_Toyk8oJI_Ktacp:APA91bFdTwv_LOUiPoyKne7G96ebiUs_c9fmOXqBv-SGOReBBf9Kd69gGcR2WAjNE4LEe8wfakt5WxhPKHwf7gutBCIpiZvCG20aGQyEmJpqRCTghfPewUw', 'android', 'FloodGuard Android device', NULL, '2026-09-28 17:53:23', '2026-10-01 02:51:02', '2026-09-28 08:40:55', '2026-09-30 18:51:02'),
(5, 7, '8d7dac351dd1404f21687409b5b23f9eb2dffe97f40200f467a48fd5e04d4940', 'cFZ5iF0UR2WlT3rfRGrm67:APA91bEp9rs7wBym2qyM4KjAj3wxbfbDPqteVEe0UNAVpxr3RPBBG3TsGhD2vfv-5mMXoZSxNUmgGCROkGXFEl94gjFSlZVREGi6R-BFdkviOb2HUKItXXQ', 'android', 'FloodGuard Android device', NULL, '2026-10-01 10:38:50', '2026-10-01 10:38:57', '2026-09-28 14:41:45', '2026-10-01 02:38:57'),
(7, 12, '66a1643c6d08539a41cf33a8a5dad9f2b8493d8a8cd421f135bc0463245cc391', 'dvUAcCIUQYyJ6O0vap-1eU:APA91bEZ7jb94Q4JQ-V8eUDIu0abdynFtQSoQbZ2f4OT2p6Apg79ruYsSxGkP7Q0187tntgUsDwVgrrgElOTYMjgg3WdNiDKU96T1I7faL8bCtR_q83oFVY', 'android', 'FloodGuard Android device', NULL, '2026-10-01 10:46:25', '2026-10-01 12:34:02', '2026-09-30 07:46:27', '2026-10-01 04:34:02'),
(17, 13, '20ea9a3e8eeac09bbe39cc08d47ccfa2d5a072dc7998d53562dd1ad41e25b39c', 'e676E-LKRSGPYjLW-y67AU:APA91bEiiuM8oPBPy3z6q_A-v0kRcAUCFUQhA5zegfP-reYfyr4B80qEdSbLHXA3ivea_tTNFUfbf77FgXukjcguau7pfXgbmsIfEhbo7aeBMJoPjrJt0wc', 'android', 'FloodGuard Android device', NULL, '2026-10-13 01:07:56', NULL, '2026-10-01 08:25:47', '2026-10-12 17:07:56');

-- --------------------------------------------------------

--
-- Table structure for table `responder_location_updates`
--

CREATE TABLE `responder_location_updates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `incident_assignment_id` bigint(20) UNSIGNED NOT NULL,
  `responder_user_id` bigint(20) UNSIGNED NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `accuracy_meters` decimal(8,2) DEFAULT NULL,
  `recorded_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `responder_location_updates`
--

INSERT INTO `responder_location_updates` (`id`, `incident_assignment_id`, `responder_user_id`, `latitude`, `longitude`, `accuracy_meters`, `recorded_at`, `created_at`) VALUES
(1, 2, 5, 37.4219983, -122.0840000, 5.00, '2026-09-20 16:22:30', '2026-09-20 08:22:30'),
(2, 3, 5, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:45:01', '2026-09-20 14:45:01'),
(3, 3, 5, 37.4219983, -122.0840000, 5.00, '2026-09-20 22:50:13', '2026-09-20 14:50:13'),
(4, 3, 5, 37.4219983, -122.0840000, 5.00, '2026-09-21 16:55:25', '2026-09-21 08:55:25'),
(5, 3, 5, 37.4219983, -122.0840000, 5.00, '2026-09-21 17:01:23', '2026-09-21 09:01:23'),
(6, 4, 5, 37.4219983, -122.0840000, 5.00, '2026-09-23 15:20:43', '2026-09-23 07:20:43'),
(7, 5, 5, 14.7416750, 121.1637887, 20.00, '2026-09-26 08:59:58', '2026-09-26 08:59:58'),
(8, 5, 5, 14.7422600, 121.1623667, 15.58, '2026-09-26 09:05:22', '2026-09-26 09:05:22'),
(9, 5, 5, 14.7421707, 121.1623203, 21.80, '2026-09-26 09:05:24', '2026-09-26 09:05:24'),
(10, 5, 5, 14.7417605, 121.1618549, 3.79, '2026-09-26 09:05:33', '2026-09-26 09:05:33'),
(11, 5, 5, 14.7416916, 121.1617694, 31.21, '2026-09-26 09:05:38', '2026-09-26 09:05:38'),
(12, 5, 5, 14.7416113, 121.1617250, 9.21, '2026-09-26 09:05:45', '2026-09-26 09:05:45'),
(13, 5, 5, 14.7416256, 121.1616150, 5.45, '2026-09-26 09:06:12', '2026-09-26 09:06:12'),
(14, 5, 5, 14.7418598, 121.1618570, 6.68, '2026-09-26 09:08:32', '2026-09-26 09:08:32'),
(15, 5, 5, 14.7421913, 121.1622700, 3.79, '2026-09-26 09:08:37', '2026-09-26 09:08:37'),
(16, 5, 5, 14.7424149, 121.1625490, 3.79, '2026-09-26 09:08:43', '2026-09-26 09:08:43'),
(17, 5, 5, 14.7422550, 121.1627823, 6.40, '2026-09-26 09:08:52', '2026-09-26 09:08:52'),
(18, 5, 5, 14.7420171, 121.1630144, 4.19, '2026-09-26 09:08:57', '2026-09-26 09:08:57'),
(19, 5, 5, 14.7418496, 121.1632376, 3.79, '2026-09-26 09:09:03', '2026-09-26 09:09:03'),
(20, 5, 5, 14.7416192, 121.1635627, 3.79, '2026-09-26 09:09:13', '2026-09-26 09:09:13'),
(21, 5, 5, 14.7416589, 121.1637236, 3.79, '2026-09-26 09:09:23', '2026-09-26 09:09:23'),
(22, 5, 5, 14.7417331, 121.1637860, 4.54, '2026-09-26 09:09:37', '2026-09-26 09:09:37'),
(23, 6, 5, 14.7416279, 121.1638249, 13.15, '2026-09-30 17:10:30', '2026-09-30 09:10:30'),
(24, 7, 11, 14.7416788, 121.1637904, 13.88, '2026-10-01 10:53:12', '2026-10-01 02:53:12'),
(25, 7, 11, 14.7416834, 121.1636962, 6.20, '2026-10-01 10:54:44', '2026-10-01 02:54:44'),
(26, 7, 11, 14.7416745, 121.1637891, 5.67, '2026-10-01 10:58:19', '2026-10-01 02:58:19'),
(27, 7, 11, 14.7416332, 121.1637013, 4.86, '2026-10-01 10:59:19', '2026-10-01 02:59:19'),
(28, 7, 11, 14.7416779, 121.1637968, 4.58, '2026-10-01 11:02:24', '2026-10-01 03:02:24'),
(29, 7, 11, 14.7416833, 121.1638383, 7.70, '2026-10-01 11:24:38', '2026-10-01 03:24:38'),
(30, 7, 11, 14.7416833, 121.1638383, 7.70, '2026-10-01 11:24:43', '2026-10-01 03:24:43'),
(31, 7, 11, 14.7415937, 121.1634055, 8.70, '2026-10-01 11:24:48', '2026-10-01 03:24:48'),
(32, 7, 11, 14.7415920, 121.1634485, 9.62, '2026-10-01 11:25:02', '2026-10-01 03:25:02'),
(33, 7, 11, 14.7416014, 121.1638982, 9.28, '2026-10-01 11:25:09', '2026-10-01 03:25:09'),
(34, 7, 11, 14.7416061, 121.1640033, 5.60, '2026-10-01 11:25:14', '2026-10-01 03:25:14'),
(35, 7, 11, 14.7415952, 121.1639042, 5.89, '2026-10-01 11:25:19', '2026-10-01 03:25:19'),
(36, 7, 11, 14.7416850, 121.1642333, 12.50, '2026-10-01 11:25:54', '2026-10-01 03:25:54'),
(37, 7, 11, 14.7416254, 121.1641429, 10.11, '2026-10-01 11:26:05', '2026-10-01 03:26:05'),
(38, 7, 11, 14.7415827, 121.1640225, 11.17, '2026-10-01 11:26:40', '2026-10-01 03:26:40'),
(39, 7, 11, 14.7415879, 121.1639115, 9.41, '2026-10-01 11:26:45', '2026-10-01 03:26:45'),
(40, 7, 11, 14.7415817, 121.1638742, 5.99, '2026-10-01 11:26:54', '2026-10-01 03:26:54'),
(41, 7, 11, 14.7429767, 121.1651300, 16.30, '2026-10-01 11:27:40', '2026-10-01 03:27:40'),
(42, 7, 11, 14.7417382, 121.1639563, 12.15, '2026-10-01 11:27:45', '2026-10-01 03:27:45'),
(43, 7, 11, 14.7416646, 121.1638428, 9.77, '2026-10-01 11:27:50', '2026-10-01 03:27:50'),
(44, 7, 11, 14.7415017, 121.1640583, 9.60, '2026-10-01 11:28:50', '2026-10-01 03:28:50'),
(45, 7, 11, 14.7415565, 121.1636683, 5.50, '2026-10-01 11:29:00', '2026-10-01 03:29:00'),
(46, 7, 11, 14.7416341, 121.1636052, 4.76, '2026-10-01 11:30:35', '2026-10-01 03:30:35'),
(47, 7, 11, 14.7416224, 121.1637070, 3.85, '2026-10-01 11:31:55', '2026-10-01 03:31:55'),
(48, 7, 11, 14.7415988, 121.1635251, 4.58, '2026-10-01 11:32:00', '2026-10-01 03:32:00'),
(49, 7, 11, 14.7415999, 121.1636228, 3.51, '2026-10-01 11:33:46', '2026-10-01 03:33:46'),
(50, 7, 11, 14.7415526, 121.1637106, 4.78, '2026-10-01 11:34:26', '2026-10-01 03:34:26'),
(51, 7, 11, 14.7416033, 121.1639300, 5.50, '2026-10-01 11:35:20', '2026-10-01 03:35:20');

-- --------------------------------------------------------

--
-- Table structure for table `response_teams`
--

CREATE TABLE `response_teams` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `team_name` varchar(120) NOT NULL,
  `duty_status` enum('off_duty','available','assigned','unavailable') NOT NULL DEFAULT 'off_duty',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `response_teams`
--

INSERT INTO `response_teams` (`id`, `team_name`, `duty_status`, `is_active`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Team A', 'assigned', 1, 3, '2026-09-09 00:51:30', '2026-09-30 09:09:37'),
(2, 'Team B', 'assigned', 1, 3, '2026-10-01 02:52:07', '2026-10-01 09:17:21'),
(3, 'Team C', 'available', 1, 3, '2026-10-01 09:16:15', '2026-10-01 09:16:15');

-- --------------------------------------------------------

--
-- Table structure for table `response_team_members`
--

CREATE TABLE `response_team_members` (
  `response_team_id` bigint(20) UNSIGNED NOT NULL,
  `responder_user_id` bigint(20) UNSIGNED NOT NULL,
  `is_team_lead` tinyint(1) NOT NULL DEFAULT 0,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `response_team_members`
--

INSERT INTO `response_team_members` (`response_team_id`, `responder_user_id`, `is_team_lead`, `joined_at`) VALUES
(1, 5, 0, '2026-09-09 00:51:50'),
(2, 11, 0, '2026-10-01 02:52:16'),
(3, 11, 0, '2026-10-01 09:16:33');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` smallint(5) UNSIGNED NOT NULL,
  `slug` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `slug`, `name`, `description`, `is_system`, `created_at`) VALUES
(1, 'resident', 'Resident', 'Verified resident using the FloodGuard mobile application.', 1, '2026-09-08 02:02:37'),
(2, 'responder', 'Responder', 'Authorized responder assigned to flood incidents.', 1, '2026-09-08 02:02:37'),
(3, 'barangay_personnel', 'Barangay Personnel', 'Reviews reports and manages barangay incident operations.', 1, '2026-09-08 02:02:37'),
(5, 'administrator', 'Administrator', 'Manages accounts, configuration, devices, security, and system health.', 1, '2026-09-08 02:02:37');

-- --------------------------------------------------------

--
-- Table structure for table `role_permissions`
--

CREATE TABLE `role_permissions` (
  `role_id` smallint(5) UNSIGNED NOT NULL,
  `permission_id` smallint(5) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `role_permissions`
--

INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES
(1, 1),
(2, 1),
(3, 1),
(5, 1),
(1, 2),
(2, 2),
(3, 2),
(5, 2),
(1, 3),
(1, 4),
(3, 5),
(3, 6),
(3, 7),
(3, 8),
(3, 9),
(3, 10),
(2, 11),
(2, 12),
(1, 13),
(2, 13),
(1, 14),
(2, 14),
(3, 14),
(5, 15),
(5, 16),
(5, 17),
(5, 18),
(5, 19),
(5, 20),
(5, 21),
(5, 22),
(1, 23),
(1, 24),
(3, 25),
(3, 26);

-- --------------------------------------------------------

--
-- Table structure for table `sensor_readings`
--

CREATE TABLE `sensor_readings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `monitoring_device_id` bigint(20) UNSIGNED DEFAULT NULL,
  `device_id` varchar(50) NOT NULL,
  `water_distance_cm` decimal(8,2) DEFAULT NULL,
  `water_level_cm` decimal(8,2) DEFAULT NULL,
  `rise_rate_cm_min` decimal(8,2) DEFAULT NULL,
  `predicted_minutes_to_warning` decimal(8,2) DEFAULT NULL,
  `prediction_status` enum('safe','watch','warning_soon','unavailable') NOT NULL DEFAULT 'unavailable',
  `sensor_health` enum('healthy','suspect','fault','unknown') NOT NULL DEFAULT 'unknown',
  `rain_analog` int(10) UNSIGNED DEFAULT NULL,
  `rain_detected` tinyint(1) NOT NULL DEFAULT 0,
  `wind_speed_mps` decimal(8,2) DEFAULT NULL,
  `north_obstacle` tinyint(1) NOT NULL DEFAULT 0,
  `south_obstacle` tinyint(1) NOT NULL DEFAULT 0,
  `north_barrier_status` varchar(30) DEFAULT 'not_connected',
  `south_barrier_status` varchar(30) DEFAULT 'not_connected',
  `battery_voltage` decimal(6,2) DEFAULT NULL,
  `battery_percent` decimal(5,2) DEFAULT NULL,
  `alert_level` enum('normal','warning','critical') NOT NULL DEFAULT 'normal',
  `device_status` enum('online','offline','sensor_error','maintenance') NOT NULL DEFAULT 'online',
  `raw_payload` text DEFAULT NULL,
  `history_sample_reason` enum('initial','scheduled_sample','significant_change') DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sensor_readings`
--

INSERT INTO `sensor_readings` (`id`, `monitoring_device_id`, `device_id`, `water_distance_cm`, `water_level_cm`, `rise_rate_cm_min`, `predicted_minutes_to_warning`, `prediction_status`, `sensor_health`, `rain_analog`, `rain_detected`, `wind_speed_mps`, `north_obstacle`, `south_obstacle`, `north_barrier_status`, `south_barrier_status`, `battery_voltage`, `battery_percent`, `alert_level`, `device_status`, `raw_payload`, `history_sample_reason`, `created_at`) VALUES
(1, 1, 'FG-STATION-001', 42.30, 107.70, 2.40, 4.80, 'warning_soon', 'healthy', 1450, 1, 1.80, 0, 0, 'closed', 'closed', 12.54, 82.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-11 12:16:34'),
(2, 1, 'FG-STATION-001', 30.50, 19.50, NULL, NULL, 'unavailable', 'healthy', 525, 0, NULL, 0, 0, 'not_connected', 'not_connected', 12.60, NULL, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 08:10:43'),
(3, 1, 'FG-STATION-001', 30.50, 19.50, NULL, NULL, 'unavailable', 'healthy', 525, 0, NULL, 0, 0, 'not_connected', 'not_connected', 12.60, NULL, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 08:17:23'),
(4, 1, 'FG-STATION-001', 39.90, 10.10, NULL, NULL, 'unavailable', 'healthy', 1968, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 08:54:56'),
(5, 1, 'FG-STATION-001', 35.60, 14.40, NULL, NULL, 'unavailable', 'healthy', 1964, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 08:55:54'),
(6, 1, 'FG-STATION-001', 46.80, 3.20, NULL, NULL, 'unavailable', 'healthy', 1967, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.44, 26.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 08:58:23'),
(7, 1, 'FG-STATION-001', 41.40, 8.60, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 08:59:07'),
(8, 1, 'FG-STATION-001', 66.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 08:59:36'),
(9, 1, 'FG-STATION-001', 36.20, 13.80, NULL, NULL, 'unavailable', 'healthy', 1971, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:00:05'),
(10, 1, 'FG-STATION-001', 20.60, 29.40, NULL, NULL, 'unavailable', 'healthy', 1969, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:00:35'),
(11, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1979, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:01:33'),
(12, 1, 'FG-STATION-001', 21.60, 28.40, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.41, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:02:03'),
(13, 1, 'FG-STATION-001', 86.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 1969, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:02:31'),
(14, 1, 'FG-STATION-001', 23.10, 26.90, NULL, NULL, 'unavailable', 'healthy', 1963, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:03:00'),
(15, 1, 'FG-STATION-001', 21.40, 28.60, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:04:00'),
(16, 1, 'FG-STATION-001', 21.30, 28.70, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:04:30'),
(17, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1969, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:04:58'),
(18, 1, 'FG-STATION-001', 20.20, 29.80, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:05:29'),
(19, 1, 'FG-STATION-001', 20.40, 29.60, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.41, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:05:58'),
(20, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:06:30'),
(21, 1, 'FG-STATION-001', 20.50, 29.50, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:06:59'),
(22, 1, 'FG-STATION-001', 20.20, 29.80, NULL, NULL, 'unavailable', 'healthy', 1968, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:07:29'),
(23, 1, 'FG-STATION-001', 26.90, 23.10, NULL, NULL, 'unavailable', 'healthy', 1982, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:07:58'),
(24, 1, 'FG-STATION-001', 38.90, 11.10, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 24.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:08:27'),
(25, 1, 'FG-STATION-001', 51.70, 0.00, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:09:26'),
(26, 1, 'FG-STATION-001', 47.80, 2.20, NULL, NULL, 'unavailable', 'healthy', 1976, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:09:56'),
(27, 1, 'FG-STATION-001', 113.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.41, 24.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:10:28'),
(28, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1979, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-14 09:11:39'),
(29, 1, 'FG-STATION-001', 50.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1968, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.26, 15.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:12:10'),
(30, 1, 'FG-STATION-001', 38.10, 11.90, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.42, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:13:08'),
(31, 1, 'FG-STATION-001', 40.20, 9.80, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:13:39'),
(32, 1, 'FG-STATION-001', 34.20, 15.80, NULL, NULL, 'unavailable', 'healthy', 1971, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.46, 27.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:21:23'),
(33, 1, 'FG-STATION-001', 27.10, 22.90, NULL, NULL, 'unavailable', 'healthy', 1982, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-14 09:22:20'),
(34, 1, 'FG-STATION-001', 39.20, 10.80, NULL, NULL, 'unavailable', 'healthy', 1969, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.43, 25.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-14 09:22:51'),
(35, 1, 'FG-STATION-001', 44.40, 5.60, NULL, NULL, 'unavailable', 'healthy', 1972, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.06, 3.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:22:55'),
(36, 1, 'FG-STATION-001', 42.70, 7.30, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:23:54'),
(37, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.05, 3.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:24:24'),
(38, 1, 'FG-STATION-001', 20.20, 29.80, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 3.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:24:54'),
(39, 1, 'FG-STATION-001', 25.10, 24.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-18 04:25:42'),
(40, 1, 'FG-STATION-001', 42.30, 7.70, NULL, NULL, 'unavailable', 'healthy', 1971, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:27:31'),
(41, 1, 'FG-STATION-001', 23.00, 27.00, NULL, NULL, 'unavailable', 'healthy', 1973, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:28:53'),
(42, 1, 'FG-STATION-001', 42.30, 7.70, NULL, NULL, 'unavailable', 'healthy', 1964, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:30:27'),
(43, 1, 'FG-STATION-001', 39.40, 10.60, NULL, NULL, 'unavailable', 'healthy', 1963, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:31:28'),
(44, 1, 'FG-STATION-001', 38.80, 11.20, NULL, NULL, 'unavailable', 'healthy', 1973, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:31:56'),
(45, 1, 'FG-STATION-001', 39.30, 10.70, NULL, NULL, 'unavailable', 'healthy', 1968, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:32:30'),
(46, 1, 'FG-STATION-001', 38.30, 11.70, NULL, NULL, 'unavailable', 'healthy', 1979, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:32:59'),
(47, 1, 'FG-STATION-001', 37.10, 12.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:33:36'),
(48, 1, 'FG-STATION-001', 35.70, 14.30, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:34:05'),
(49, 1, 'FG-STATION-001', 37.00, 13.00, NULL, NULL, 'unavailable', 'healthy', 1973, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:34:35'),
(50, 1, 'FG-STATION-001', 36.80, 13.20, NULL, NULL, 'unavailable', 'healthy', 1972, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:35:05'),
(51, 1, 'FG-STATION-001', 36.90, 13.10, NULL, NULL, 'unavailable', 'healthy', 1970, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:35:35'),
(52, 1, 'FG-STATION-001', 30.70, 19.30, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-18 04:36:07'),
(53, 1, 'FG-STATION-001', 32.60, 17.40, NULL, NULL, 'unavailable', 'healthy', 1964, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-18 04:37:17'),
(54, 1, 'FG-STATION-001', 33.20, 16.80, NULL, NULL, 'unavailable', 'healthy', 1979, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 3.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-18 04:37:49'),
(55, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1974, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:38:19'),
(56, 1, 'FG-STATION-001', 20.40, 29.60, NULL, NULL, 'unavailable', 'healthy', 1969, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:39:18'),
(57, 1, 'FG-STATION-001', 24.10, 25.90, NULL, NULL, 'unavailable', 'healthy', 1977, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:39:47'),
(58, 1, 'FG-STATION-001', 20.40, 29.60, NULL, NULL, 'unavailable', 'healthy', 1971, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:40:18'),
(59, 1, 'FG-STATION-001', 38.90, 11.10, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:41:15'),
(60, 1, 'FG-STATION-001', 39.40, 10.60, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:42:14'),
(61, 1, 'FG-STATION-001', 45.20, 4.80, NULL, NULL, 'unavailable', 'healthy', 1967, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:51:23'),
(62, 1, 'FG-STATION-001', 39.00, 11.00, NULL, NULL, 'unavailable', 'healthy', 1976, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:52:22'),
(63, 1, 'FG-STATION-001', 20.20, 29.80, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-18 04:52:54'),
(64, 1, 'FG-STATION-001', 38.80, 11.20, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 10.87, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:53:24'),
(65, 1, 'FG-STATION-001', 45.30, 4.70, NULL, NULL, 'unavailable', 'healthy', 1977, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:54:23'),
(66, 1, 'FG-STATION-001', 44.80, 5.20, NULL, NULL, 'unavailable', 'healthy', 1973, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:54:54'),
(67, 1, 'FG-STATION-001', 30.40, 19.60, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 1.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-18 04:55:47'),
(68, 1, 'FG-STATION-001', 42.40, 7.60, NULL, NULL, 'unavailable', 'healthy', 1976, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:56:24'),
(69, 1, 'FG-STATION-001', 43.70, 6.30, NULL, NULL, 'unavailable', 'healthy', 1979, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:57:25'),
(70, 1, 'FG-STATION-001', 45.90, 4.10, NULL, NULL, 'unavailable', 'healthy', 1992, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 04:59:44'),
(71, 1, 'FG-STATION-001', 44.20, 5.80, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:00:25'),
(72, 1, 'FG-STATION-001', 43.80, 6.20, NULL, NULL, 'unavailable', 'healthy', 1971, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:00:55'),
(73, 1, 'FG-STATION-001', 41.20, 8.80, NULL, NULL, 'unavailable', 'healthy', 1982, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.01, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:01:25'),
(74, 1, 'FG-STATION-001', 39.70, 10.30, NULL, NULL, 'unavailable', 'healthy', 1975, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:01:54'),
(75, 1, 'FG-STATION-001', 41.30, 8.70, NULL, NULL, 'unavailable', 'healthy', 1977, 0, NULL, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:02:24'),
(76, 1, 'FG-STATION-001', NULL, NULL, NULL, NULL, 'unavailable', 'fault', 1968, 0, 2.10, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'sensor_error', NULL, 'scheduled_sample', '2026-08-18 05:18:53'),
(77, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 1.78, 0, 0, 'not_connected', 'not_connected', 11.03, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:19:46'),
(78, 1, 'FG-STATION-001', 41.80, 8.20, NULL, NULL, 'unavailable', 'healthy', 1976, 0, 1.79, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:20:34'),
(79, 1, 'FG-STATION-001', 44.20, 5.80, NULL, NULL, 'unavailable', 'healthy', 1972, 0, 1.66, 0, 0, 'not_connected', 'not_connected', 11.02, 1.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:21:10'),
(80, 1, 'FG-STATION-001', 46.20, 3.80, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 2.23, 0, 0, 'not_connected', 'not_connected', 11.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:21:35'),
(81, 1, 'FG-STATION-001', 43.70, 6.30, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 1.01, 0, 0, 'not_connected', 'not_connected', 11.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:22:05'),
(82, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1969, 0, 1.84, 0, 0, 'not_connected', 'not_connected', 11.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:22:34'),
(83, 1, 'FG-STATION-001', 44.50, 5.50, NULL, NULL, 'unavailable', 'healthy', 1975, 0, 2.06, 0, 0, 'not_connected', 'not_connected', 11.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:23:04'),
(84, 1, 'FG-STATION-001', 43.90, 6.10, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 1.77, 0, 0, 'not_connected', 'not_connected', 11.04, 2.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-18 05:46:15'),
(85, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1975, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.88, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:50:27'),
(86, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.88, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:51:12'),
(87, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.87, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:52:01'),
(88, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.86, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:52:32'),
(89, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:53:05'),
(90, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.86, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:53:40'),
(91, 1, 'FG-STATION-001', 38.60, 11.40, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:54:06'),
(92, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:54:47'),
(93, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.86, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:55:09'),
(94, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1976, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:55:45'),
(95, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:56:12'),
(96, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:56:44'),
(97, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:57:14'),
(98, 1, 'FG-STATION-001', 35.90, 14.10, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:57:47'),
(99, 1, 'FG-STATION-001', 36.50, 13.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:58:20'),
(100, 1, 'FG-STATION-001', 36.60, 13.40, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:58:49'),
(101, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.01, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 04:59:33'),
(102, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:00:36'),
(103, 1, 'FG-STATION-001', 43.00, 7.00, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:00:59'),
(104, 1, 'FG-STATION-001', 42.60, 7.40, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.05, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:01:32'),
(105, 1, 'FG-STATION-001', 43.00, 7.00, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.10, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:02:03'),
(106, 1, 'FG-STATION-001', 43.00, 7.00, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:02:36'),
(107, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:03:09'),
(108, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:03:44'),
(109, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.86, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:05:16'),
(110, 1, 'FG-STATION-001', 43.30, 6.70, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:06:04'),
(111, 1, 'FG-STATION-001', 43.20, 6.80, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.06, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:06:37'),
(112, 1, 'FG-STATION-001', 44.00, 6.00, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:07:23'),
(113, 1, 'FG-STATION-001', 44.50, 5.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:07:56'),
(114, 1, 'FG-STATION-001', 44.10, 5.90, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.02, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:08:27'),
(115, 1, 'FG-STATION-001', 44.10, 5.90, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:08:58'),
(116, 1, 'FG-STATION-001', 44.50, 5.50, NULL, NULL, 'unavailable', 'healthy', 1973, 0, 0.02, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:09:30'),
(117, 1, 'FG-STATION-001', 44.00, 6.00, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.07, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:10:09'),
(118, 1, 'FG-STATION-001', 44.30, 5.70, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.06, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:10:41'),
(119, 1, 'FG-STATION-001', 44.50, 5.50, NULL, NULL, 'unavailable', 'healthy', 1973, 0, 0.14, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:11:13'),
(120, 1, 'FG-STATION-001', 44.10, 5.90, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:11:52'),
(121, 1, 'FG-STATION-001', 44.00, 6.00, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.02, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:12:23'),
(122, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.06, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:13:01'),
(123, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:13:25'),
(124, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.03, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:14:00'),
(125, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:14:32'),
(126, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:15:07'),
(127, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:15:34'),
(128, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.03, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:16:13'),
(129, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.08, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:16:44'),
(130, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.02, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:17:19'),
(131, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:17:55'),
(132, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:18:22'),
(133, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:19:02'),
(134, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:19:28'),
(135, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:20:12'),
(136, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:20:45'),
(137, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:21:19'),
(138, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:21:47'),
(139, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:22:18'),
(140, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:22:50'),
(141, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 2000, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:23:23'),
(142, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:23:58'),
(143, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:24:30'),
(144, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:25:04'),
(145, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:25:38'),
(146, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:26:11'),
(147, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.01, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:27:24'),
(148, 1, 'FG-STATION-001', 48.90, 1.10, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:28:13'),
(149, 1, 'FG-STATION-001', 47.70, 2.30, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:28:45'),
(150, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:29:16'),
(151, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:29:47'),
(152, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:30:35'),
(153, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:31:12'),
(154, 1, 'FG-STATION-001', 46.80, 3.20, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:31:39'),
(155, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:32:12'),
(156, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:32:44'),
(157, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:33:15'),
(158, 1, 'FG-STATION-001', 28.80, 21.20, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 05:33:39'),
(159, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:34:01'),
(160, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:34:49'),
(161, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:35:28'),
(162, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:35:52'),
(163, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:36:48'),
(164, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1973, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:37:40'),
(165, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:38:11'),
(166, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:38:44'),
(167, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:39:25'),
(168, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:39:59'),
(169, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:40:21'),
(170, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:40:54'),
(171, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:41:39'),
(172, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:42:02'),
(173, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:42:37'),
(174, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:43:04'),
(175, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:43:37'),
(176, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:44:08'),
(177, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:44:44'),
(178, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:45:11'),
(179, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:45:46'),
(180, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:46:19'),
(181, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:47:04'),
(182, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:47:36'),
(183, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:48:07'),
(184, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:48:39'),
(185, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:49:11'),
(186, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:49:46'),
(187, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:50:14'),
(188, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:50:27'),
(189, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:50:58'),
(190, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:51:30'),
(191, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1972, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:51:58'),
(192, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:52:28'),
(193, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:52:58'),
(194, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:53:28'),
(195, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:54:01'),
(196, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:54:28'),
(197, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:54:58'),
(198, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:55:33'),
(199, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:55:46'),
(200, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1992, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:56:18'),
(201, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:57:01'),
(202, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:57:18'),
(203, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:57:48'),
(204, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:58:24'),
(205, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:58:48'),
(206, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:59:18'),
(207, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 05:59:48'),
(208, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:00:18'),
(209, 1, 'FG-STATION-001', 44.80, 5.20, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:00:56'),
(210, 1, 'FG-STATION-001', 45.70, 4.30, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:01:27'),
(211, 1, 'FG-STATION-001', 45.60, 4.40, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:01:56'),
(212, 1, 'FG-STATION-001', 45.70, 4.30, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:02:26'),
(213, 1, 'FG-STATION-001', 45.60, 4.40, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:02:56'),
(214, 1, 'FG-STATION-001', 45.60, 4.40, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:03:26'),
(215, 1, 'FG-STATION-001', 46.10, 3.90, NULL, NULL, 'unavailable', 'healthy', 1975, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:03:56'),
(216, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:04:26'),
(217, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:04:48'),
(218, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:05:22'),
(219, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:05:52'),
(220, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:06:22'),
(221, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:06:52'),
(222, 1, 'FG-STATION-001', 31.10, 18.90, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:07:04'),
(223, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:07:59'),
(224, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:08:30'),
(225, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:09:00'),
(226, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:09:37'),
(227, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:10:05'),
(228, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:10:35'),
(229, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:11:05'),
(230, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:11:35'),
(231, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:12:05');
INSERT INTO `sensor_readings` (`id`, `monitoring_device_id`, `device_id`, `water_distance_cm`, `water_level_cm`, `rise_rate_cm_min`, `predicted_minutes_to_warning`, `prediction_status`, `sensor_health`, `rain_analog`, `rain_detected`, `wind_speed_mps`, `north_obstacle`, `south_obstacle`, `north_barrier_status`, `south_barrier_status`, `battery_voltage`, `battery_percent`, `alert_level`, `device_status`, `raw_payload`, `history_sample_reason`, `created_at`) VALUES
(232, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:12:35'),
(233, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1993, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:13:06'),
(234, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:13:38'),
(235, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:14:06'),
(236, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:14:36'),
(237, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:15:06'),
(238, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:15:35'),
(239, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:16:06'),
(240, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:16:36'),
(241, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:17:06'),
(242, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:17:36'),
(243, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:18:06'),
(244, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:18:37'),
(245, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:19:07'),
(246, 1, 'FG-STATION-001', 46.30, 3.70, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:20:04'),
(247, 1, 'FG-STATION-001', 31.40, 18.60, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:20:12'),
(248, 1, 'FG-STATION-001', 68.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:20:26'),
(249, 1, 'FG-STATION-001', 30.90, 19.10, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:20:39'),
(250, 1, 'FG-STATION-001', 77.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:20:54'),
(251, 1, 'FG-STATION-001', 33.10, 16.90, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:12'),
(252, 1, 'FG-STATION-001', 74.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 1996, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:16'),
(253, 1, 'FG-STATION-001', 22.40, 27.60, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:18'),
(254, 1, 'FG-STATION-001', 52.60, 0.00, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.02, 0, 0, 'not_connected', 'not_connected', 10.80, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:22'),
(255, 1, 'FG-STATION-001', 31.10, 18.90, NULL, NULL, 'unavailable', 'healthy', 1994, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:31'),
(256, 1, 'FG-STATION-001', 42.40, 7.60, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:21:52'),
(257, 1, 'FG-STATION-001', 43.60, 6.40, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:22:23'),
(258, 1, 'FG-STATION-001', 42.30, 7.70, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:22:55'),
(259, 1, 'FG-STATION-001', 43.60, 6.40, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:23:23'),
(260, 1, 'FG-STATION-001', 43.60, 6.40, NULL, NULL, 'unavailable', 'healthy', 1993, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:23:53'),
(261, 1, 'FG-STATION-001', 42.80, 7.20, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:24:26'),
(262, 1, 'FG-STATION-001', 43.20, 6.80, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:24:57'),
(263, 1, 'FG-STATION-001', 42.80, 7.20, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:25:36'),
(264, 1, 'FG-STATION-001', 42.80, 7.20, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:26:10'),
(265, 1, 'FG-STATION-001', 43.50, 6.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:26:35'),
(266, 1, 'FG-STATION-001', 43.20, 6.80, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.85, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:27:05'),
(267, 1, 'FG-STATION-001', 43.20, 6.80, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:27:39'),
(268, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:28:09'),
(269, 1, 'FG-STATION-001', 48.90, 1.10, NULL, NULL, 'unavailable', 'healthy', 1995, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:28:39'),
(270, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:29:09'),
(271, 1, 'FG-STATION-001', 31.40, 18.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:29:29'),
(272, 1, 'FG-STATION-001', 31.40, 18.60, NULL, NULL, 'unavailable', 'healthy', 1992, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:30:03'),
(273, 1, 'FG-STATION-001', 31.40, 18.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.84, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:30:30'),
(274, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:30:46'),
(275, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:31:17'),
(276, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:31:49'),
(277, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1997, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:32:17'),
(278, 1, 'FG-STATION-001', 32.00, 18.00, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:32:23'),
(279, 1, 'FG-STATION-001', 32.00, 18.00, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-20 06:32:57'),
(280, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:33:00'),
(281, 1, 'FG-STATION-001', 23.20, 26.80, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-20 06:33:18'),
(282, 1, 'FG-STATION-001', 52.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.06, 0, 0, 'not_connected', 'not_connected', 10.81, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:33:22'),
(283, 1, 'FG-STATION-001', 21.70, 28.30, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-20 06:33:24'),
(284, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1992, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:33:28'),
(285, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1994, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.82, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:34:00'),
(286, 1, 'FG-STATION-001', 48.90, 1.10, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 10.83, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-20 06:34:30'),
(287, 1, 'FG-STATION-001', 37.80, 12.20, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 0.00, 0.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:13:17'),
(288, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 2.10, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:13:46'),
(289, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 2.67, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:14:16'),
(290, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 1.90, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:14:46'),
(291, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 2.76, 0, 0, 'not_connected', 'not_connected', 11.35, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:15:16'),
(292, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 2.49, 0, 0, 'not_connected', 'not_connected', 11.35, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:15:50'),
(293, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 2.62, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:16:21'),
(294, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 2.80, 0, 0, 'not_connected', 'not_connected', 11.35, 21.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:16:53'),
(295, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 2.32, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:17:23'),
(296, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 2.24, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:17:53'),
(297, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 2.71, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:18:23'),
(298, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 2.93, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:18:54'),
(299, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 2.89, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:19:26'),
(300, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 3.28, 0, 0, 'not_connected', 'not_connected', 11.35, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:19:56'),
(301, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 2.84, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:20:29'),
(302, 1, 'FG-STATION-001', 38.40, 11.60, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 3.37, 0, 0, 'not_connected', 'not_connected', 11.35, 21.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:20:59'),
(303, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 1.23, 0, 0, 'not_connected', 'not_connected', 11.35, 21.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:34:24'),
(304, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 2.17, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:34:53'),
(305, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 1.75, 0, 0, 'not_connected', 'not_connected', 11.36, 21.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:35:25'),
(306, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.17, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:35:55'),
(307, 1, 'FG-STATION-001', 48.60, 1.40, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.48, 0, 0, 'not_connected', 'not_connected', 11.36, 21.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:36:26'),
(308, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.84, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:36:55'),
(309, 1, 'FG-STATION-001', 24.30, 25.70, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 1.05, 0, 0, 'not_connected', 'not_connected', 11.38, 22.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-24 06:37:22'),
(310, 1, 'FG-STATION-001', 26.50, 23.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 1.07, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-24 06:37:27'),
(311, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.57, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:37:38'),
(312, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.79, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:38:09'),
(313, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 1.09, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:38:40'),
(314, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 1.92, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:39:20'),
(315, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 2.23, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:39:50'),
(316, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.88, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:40:25'),
(317, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1995, 0, 0.52, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:40:49'),
(318, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.39, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:41:20'),
(319, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.48, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:41:53'),
(320, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1969, 0, 0.14, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:42:04'),
(321, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.88, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:42:34'),
(322, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.17, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:43:04'),
(323, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.31, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:43:35'),
(324, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.79, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:44:05'),
(325, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 1.49, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:44:35'),
(326, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 1.07, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:45:11'),
(327, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.70, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:45:42'),
(328, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 1.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:46:12'),
(329, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1993, 0, 1.18, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:46:42'),
(330, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.88, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:47:15'),
(331, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:47:45'),
(332, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1996, 0, 2.01, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:48:18'),
(333, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1975, 0, 0.11, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:48:48'),
(334, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.92, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:49:21'),
(335, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.79, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:49:51'),
(336, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.35, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:50:23'),
(337, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 1.01, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:50:53'),
(338, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.79, 0, 0, 'not_connected', 'not_connected', 11.34, 20.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:51:28'),
(339, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1992, 0, 0.92, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:51:53'),
(340, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.39, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:52:23'),
(341, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'maintenance', NULL, 'scheduled_sample', '2026-08-24 06:53:07'),
(342, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1994, 0, 0.95, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:53:12'),
(343, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1995, 0, 0.57, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:53:43'),
(344, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.17, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:54:13'),
(345, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.26, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:54:43'),
(346, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.74, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:55:13'),
(347, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.52, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:55:47'),
(348, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.52, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:56:17'),
(349, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.35, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:56:48'),
(350, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 197, 1, 0.47, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-24 06:56:56'),
(351, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 305, 1, 0.22, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-24 06:57:32'),
(352, 1, 'FG-STATION-001', 43.00, 7.00, NULL, NULL, 'unavailable', 'healthy', 1995, 0, 0.34, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:57:34'),
(353, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.39, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:58:05'),
(354, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.61, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:58:39'),
(355, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 6.96, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:59:08'),
(356, 1, 'FG-STATION-001', 31.80, 18.20, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 4.55, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-24 06:59:31'),
(357, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 6.52, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 06:59:48'),
(358, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:00:19'),
(359, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:00:49'),
(360, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:01:20'),
(361, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1980, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:02:31'),
(362, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1973, 0, 0.01, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:03:01'),
(363, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:03:31'),
(364, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1977, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:04:01'),
(365, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.33, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:04:45'),
(366, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 356, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 11.28, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:05:16'),
(367, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 493, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:05:49'),
(368, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 579, 1, 5.60, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:06:20'),
(369, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 589, 1, 1.01, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:06:51'),
(370, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 621, 1, 0.52, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:07:22'),
(371, 1, 'FG-STATION-001', 41.20, 8.80, NULL, NULL, 'unavailable', 'healthy', 647, 1, 0.35, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:07:51'),
(372, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 671, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 11.27, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:08:21'),
(373, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 694, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:08:51'),
(374, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 723, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:09:21'),
(375, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 750, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:09:52'),
(376, 1, 'FG-STATION-001', 41.20, 8.80, NULL, NULL, 'unavailable', 'healthy', 779, 1, 0.05, 0, 0, 'not_connected', 'not_connected', 11.27, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:10:22'),
(377, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 812, 1, 0.13, 0, 0, 'not_connected', 'not_connected', 11.26, 15.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:10:52'),
(378, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 846, 1, 0.09, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:11:33'),
(379, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 858, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 11.28, 16.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:11:52'),
(380, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 866, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:12:22'),
(381, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 11.33, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:12:52'),
(382, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.08, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:13:22'),
(383, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:13:52'),
(384, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:14:22'),
(385, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:14:52'),
(386, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:15:23'),
(387, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:15:53'),
(388, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.61, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:16:23'),
(389, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.75, 0, 0, 'not_connected', 'not_connected', 11.28, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:16:53'),
(390, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.68, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:17:23'),
(391, 1, 'FG-STATION-001', 35.80, 14.20, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.52, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:17:53'),
(392, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.61, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:18:23'),
(393, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1981, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:18:59'),
(394, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.07, 0, 0, 'not_connected', 'not_connected', 11.28, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:19:29'),
(395, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:20:03'),
(396, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.39, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:20:33'),
(397, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:21:06'),
(398, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:21:35'),
(399, 1, 'FG-STATION-001', 35.40, 14.60, NULL, NULL, 'unavailable', 'healthy', 1992, 0, 0.35, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:22:07'),
(400, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, 0.74, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:45:04'),
(401, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1988, 0, 0.83, 0, 0, 'not_connected', 'not_connected', 11.35, 20.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:45:31'),
(402, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1984, 0, 0.17, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:46:07'),
(403, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:46:37'),
(404, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:47:11'),
(405, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:47:41'),
(406, 1, 'FG-STATION-001', 41.60, 8.40, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:48:13'),
(407, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1974, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:54:01'),
(408, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:54:31'),
(409, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:55:01'),
(410, 1, 'FG-STATION-001', 41.10, 8.90, NULL, NULL, 'unavailable', 'healthy', 1994, 0, 0.57, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:57:32'),
(411, 1, 'FG-STATION-001', 41.60, 8.40, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:57:59'),
(412, 1, 'FG-STATION-001', 41.60, 8.40, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:58:29'),
(413, 1, 'FG-STATION-001', 48.90, 1.10, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.12, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:58:59'),
(414, 1, 'FG-STATION-001', 48.90, 1.10, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 11.32, 19.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:59:29'),
(415, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1978, 0, 0.22, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 07:59:59'),
(416, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1979, 0, 0.31, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:01:50'),
(417, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1990, 0, 0.60, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:02:15'),
(418, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1982, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:02:45'),
(419, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.28, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:03:17'),
(420, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.30, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:03:47'),
(421, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:04:32'),
(422, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1985, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.29, 17.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:05:03'),
(423, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1987, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:08:01'),
(424, 1, 'FG-STATION-001', 48.50, 1.50, NULL, NULL, 'unavailable', 'healthy', 1989, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 11.31, 18.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-24 08:08:30'),
(425, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.19, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:03:32'),
(426, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.15, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:03:59'),
(427, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.14, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:04:29'),
(428, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.14, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:04:59'),
(429, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.14, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:05:29'),
(430, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.12, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:06:10'),
(431, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:06:29'),
(432, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:07:02'),
(433, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:07:32'),
(434, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:08:02'),
(435, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:08:32'),
(436, 1, 'FG-STATION-001', 49.20, 0.80, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.12, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:09:08'),
(437, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:09:39'),
(438, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:10:09'),
(439, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:10:40'),
(440, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.10, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:11:10'),
(441, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:11:42'),
(442, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:12:35'),
(443, 1, 'FG-STATION-001', 49.30, 0.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:13:06'),
(444, 1, 'FG-STATION-001', 49.10, 0.90, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 13.12, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:34:29'),
(445, 1, 'FG-STATION-001', 49.10, 0.90, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 13.11, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:34:58'),
(446, 1, 'FG-STATION-001', 49.00, 1.00, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.10, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:35:28'),
(447, 1, 'FG-STATION-001', 49.00, 1.00, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.09, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:35:58'),
(448, 1, 'FG-STATION-001', 49.00, 1.00, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.11, 0, 0, 'not_connected', 'not_connected', 13.09, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:36:28'),
(449, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.08, 100.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-25 15:36:44'),
(450, 1, 'FG-STATION-001', 43.20, 6.80, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.03, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 15:36:47'),
(451, 1, 'FG-STATION-001', 31.60, 18.40, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.09, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:18:36'),
(452, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.08, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:18:40'),
(453, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.06, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:19:12'),
(454, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.05, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:19:42'),
(455, 1, 'FG-STATION-001', 32.10, 17.90, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:20:10'),
(456, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1937, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:20:12'),
(457, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:20:43'),
(458, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:21:13'),
(459, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:21:43'),
(460, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:22:13');
INSERT INTO `sensor_readings` (`id`, `monitoring_device_id`, `device_id`, `water_distance_cm`, `water_level_cm`, `rise_rate_cm_min`, `predicted_minutes_to_warning`, `prediction_status`, `sensor_health`, `rain_analog`, `rain_detected`, `wind_speed_mps`, `north_obstacle`, `south_obstacle`, `north_barrier_status`, `south_barrier_status`, `battery_voltage`, `battery_percent`, `alert_level`, `device_status`, `raw_payload`, `history_sample_reason`, `created_at`) VALUES
(461, 1, 'FG-STATION-001', 28.50, 21.50, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:22:39'),
(462, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1947, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:22:42'),
(463, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:23:14'),
(464, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:23:44'),
(465, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1948, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:24:14'),
(466, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1948, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:24:44'),
(467, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1947, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:25:16'),
(468, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1948, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.91, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:25:45'),
(469, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1949, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.02, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:26:17'),
(470, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1949, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:26:45'),
(471, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:27:17'),
(472, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1949, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:27:46'),
(473, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1950, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:28:16'),
(474, 1, 'FG-STATION-001', 47.70, 2.30, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.07, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:31:06'),
(475, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 504, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:31:32'),
(476, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1949, 0, 7.22, 0, 0, 'not_connected', 'not_connected', 13.04, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:02'),
(477, 1, 'FG-STATION-001', 31.70, 18.30, NULL, NULL, 'unavailable', 'healthy', 1950, 0, 0.52, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:26'),
(478, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1950, 0, 0.22, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:34'),
(479, 1, 'FG-STATION-001', 30.50, 19.50, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.16, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:38'),
(480, 1, 'FG-STATION-001', 24.90, 25.10, NULL, NULL, 'unavailable', 'healthy', 1950, 0, 0.08, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:42'),
(481, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:44'),
(482, 1, 'FG-STATION-001', 32.20, 17.80, NULL, NULL, 'unavailable', 'healthy', 1953, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.02, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:32:57'),
(483, 1, 'FG-STATION-001', 37.00, 13.00, NULL, NULL, 'unavailable', 'healthy', 1953, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.02, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:33:15'),
(484, 1, 'FG-STATION-001', 29.70, 20.30, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.01, 100.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-08-25 17:33:19'),
(485, 1, 'FG-STATION-001', 45.80, 4.20, NULL, NULL, 'unavailable', 'healthy', 1951, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.01, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:33:23'),
(486, 1, 'FG-STATION-001', 47.40, 2.60, NULL, NULL, 'unavailable', 'healthy', 1952, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.02, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 17:34:01'),
(487, 1, 'FG-STATION-001', 52.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1968, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:22:41'),
(488, 1, 'FG-STATION-001', 51.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1968, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:23:12'),
(489, 1, 'FG-STATION-001', 52.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1969, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.02, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:24:16'),
(490, 1, 'FG-STATION-001', 51.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.99, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:24:47'),
(491, 1, 'FG-STATION-001', 52.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:25:16'),
(492, 1, 'FG-STATION-001', 52.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 1970, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.97, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:25:47'),
(493, 1, 'FG-STATION-001', 52.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1972, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.97, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:26:17'),
(494, 1, 'FG-STATION-001', 65.60, 0.00, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:26:31'),
(495, 1, 'FG-STATION-001', 52.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1974, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:27:02'),
(496, 1, 'FG-STATION-001', 65.60, 0.00, NULL, NULL, 'unavailable', 'healthy', 1970, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:27:33'),
(497, 1, 'FG-STATION-001', 52.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 1983, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:28:06'),
(498, 1, 'FG-STATION-001', 52.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1968, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.97, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 22:28:37'),
(499, 1, 'FG-STATION-001', 47.60, 2.40, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 13.03, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:39:08'),
(500, 1, 'FG-STATION-001', 47.70, 2.30, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 13.00, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:39:35'),
(501, 1, 'FG-STATION-001', 47.60, 2.40, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:40:05'),
(502, 1, 'FG-STATION-001', 47.60, 2.40, NULL, NULL, 'unavailable', 'healthy', 1947, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:40:35'),
(503, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:41:05'),
(504, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1939, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:41:37'),
(505, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:42:06'),
(506, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:42:37'),
(507, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1947, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.98, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:43:06'),
(508, 1, 'FG-STATION-001', 47.50, 2.50, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.03, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:43:37'),
(509, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1926, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:44:07'),
(510, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:44:37'),
(511, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:45:07'),
(512, 1, 'FG-STATION-001', 47.00, 3.00, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:45:37'),
(513, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:46:07'),
(514, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1950, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:46:37'),
(515, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 718, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 12.88, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:47:08'),
(516, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 974, 1, 0.04, 0, 0, 'not_connected', 'not_connected', 12.92, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:47:37'),
(517, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1054, 1, 0.00, 0, 0, 'not_connected', 'not_connected', 12.92, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:48:08'),
(518, 1, 'FG-STATION-001', 20.40, 29.60, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-25 23:48:33'),
(519, 1, 'FG-STATION-001', 44.80, 5.20, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.83, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:48:35'),
(520, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:49:06'),
(521, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:49:36'),
(522, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:50:06'),
(523, 1, 'FG-STATION-001', 20.30, 29.70, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'critical', 'online', NULL, 'scheduled_sample', '2026-08-25 23:50:19'),
(524, 1, 'FG-STATION-001', 40.80, 9.20, NULL, NULL, 'unavailable', 'healthy', 1934, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.84, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:50:21'),
(525, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:50:52'),
(526, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:51:22'),
(527, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:51:52'),
(528, 1, 'FG-STATION-001', 47.10, 2.90, NULL, NULL, 'unavailable', 'healthy', 1946, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:52:22'),
(529, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:52:52'),
(530, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1953, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:53:22'),
(531, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1952, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:53:52'),
(532, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:54:22'),
(533, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1954, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:54:52'),
(534, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:55:22'),
(535, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1947, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:55:52'),
(536, 1, 'FG-STATION-001', 47.30, 2.70, NULL, NULL, 'unavailable', 'healthy', 1960, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:56:23'),
(537, 1, 'FG-STATION-001', 46.60, 3.40, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:56:53'),
(538, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1938, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:57:23'),
(539, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:57:53'),
(540, 1, 'FG-STATION-001', 46.90, 3.10, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:58:23'),
(541, 1, 'FG-STATION-001', 47.30, 2.70, NULL, NULL, 'unavailable', 'healthy', 1940, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:58:53'),
(542, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1932, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:59:23'),
(543, 1, 'FG-STATION-001', 47.30, 2.70, NULL, NULL, 'unavailable', 'healthy', 1948, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-25 23:59:54'),
(544, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1956, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.92, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:00:23'),
(545, 1, 'FG-STATION-001', 47.30, 2.70, NULL, NULL, 'unavailable', 'healthy', 1941, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:00:54'),
(546, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1943, 0, 0.13, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:01:23'),
(547, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1945, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.95, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:01:54'),
(548, 1, 'FG-STATION-001', 47.30, 2.70, NULL, NULL, 'unavailable', 'healthy', 1944, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.93, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:02:24'),
(549, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1942, 0, 0.04, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:02:54'),
(550, 1, 'FG-STATION-001', 47.20, 2.80, NULL, NULL, 'unavailable', 'healthy', 1935, 0, 0.09, 0, 0, 'not_connected', 'not_connected', 12.94, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-08-26 00:03:24'),
(551, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', '{\r\n    \"water_distance_cm\":  40,\r\n    \"south_barrier_status\":  \"open\",\r\n    \"alert_level\":  \"normal\",\r\n    \"rain_analog\":  1900,\r\n    \"device_id\":  \"FG-STATION-001\",\r\n    \"wind_speed_mps\":  0,\r\n    \"water_level_cm\":  10,\r\n    \"device_status\":  \"online\",\r\n    \"battery_voltage\":  12.5,\r\n    \"battery_percent\":  80,\r\n    \"north_obstacle\":  false,\r\n    \"sensor_health\":  \"healthy\",\r\n    \"north_barrier_status\":  \"open\",\r\n    \"rain_detected\":  false,\r\n    \"south_obstacle\":  false\r\n}', 'scheduled_sample', '2026-09-08 02:09:24'),
(552, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', '{\r\n    \"water_distance_cm\":  40,\r\n    \"south_barrier_status\":  \"open\",\r\n    \"alert_level\":  \"normal\",\r\n    \"rain_analog\":  1900,\r\n    \"device_id\":  \"FG-STATION-001\",\r\n    \"wind_speed_mps\":  0,\r\n    \"water_level_cm\":  10,\r\n    \"device_status\":  \"online\",\r\n    \"battery_voltage\":  12.5,\r\n    \"battery_percent\":  80,\r\n    \"north_obstacle\":  false,\r\n    \"sensor_health\":  \"healthy\",\r\n    \"north_barrier_status\":  \"open\",\r\n    \"rain_detected\":  false,\r\n    \"south_obstacle\":  false\r\n}', 'scheduled_sample', '2026-09-08 02:26:13'),
(553, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', '{\r\n    \"water_distance_cm\":  40,\r\n    \"south_barrier_status\":  \"open\",\r\n    \"alert_level\":  \"normal\",\r\n    \"rain_analog\":  1900,\r\n    \"device_id\":  \"FG-STATION-001\",\r\n    \"wind_speed_mps\":  0,\r\n    \"water_level_cm\":  10,\r\n    \"device_status\":  \"online\",\r\n    \"battery_voltage\":  12.5,\r\n    \"battery_percent\":  80,\r\n    \"north_obstacle\":  false,\r\n    \"sensor_health\":  \"healthy\",\r\n    \"north_barrier_status\":  \"open\",\r\n    \"rain_detected\":  false,\r\n    \"south_obstacle\":  false\r\n}', 'scheduled_sample', '2026-09-08 02:27:36'),
(554, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-08 03:19:28'),
(555, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-08 03:22:57'),
(556, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'open', 'open', 12.50, 80.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-08 03:31:01'),
(557, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'normal', 'online', NULL, 'significant_change', '2026-09-10 02:48:48'),
(558, 1, 'FG-STATION-001', 34.00, 16.00, NULL, NULL, 'unavailable', 'healthy', 1200, 1, 1.20, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'warning', 'online', NULL, 'significant_change', '2026-09-10 02:56:56'),
(559, 1, 'FG-STATION-001', 40.00, 10.00, NULL, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'normal', 'online', NULL, 'significant_change', '2026-09-10 05:50:12'),
(560, 1, 'FG-STATION-001', 34.00, 16.00, NULL, NULL, 'unavailable', 'healthy', 900, 1, 1.20, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'warning', 'online', NULL, 'significant_change', '2026-09-20 02:47:50'),
(561, 1, 'FG-STATION-001', 40.00, 10.00, 1.00, NULL, 'unavailable', 'healthy', 1800, 1, 2.50, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'warning', 'online', NULL, 'significant_change', '2026-09-28 11:47:25'),
(562, 1, 'FG-STATION-001', 20.00, 30.00, 4.00, NULL, 'unavailable', 'healthy', 2200, 1, 4.50, 0, 0, 'not_connected', 'not_connected', 12.40, 78.00, 'critical', 'online', NULL, 'significant_change', '2026-09-28 12:01:12'),
(563, 1, 'FG-STATION-001', 50.00, 0.00, 0.00, NULL, 'unavailable', 'healthy', 1900, 0, 0.00, 0, 0, 'not_connected', 'not_connected', 12.50, 80.00, 'normal', 'online', NULL, 'significant_change', '2026-09-28 12:02:49'),
(564, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:46:41'),
(565, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1970, 0, 0.00, 0, 1, 'open', 'blocked', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:49:15'),
(566, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:50:17'),
(567, 1, 'FG-STATION-001', 20.30, 22.90, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.00, 0, 1, 'open', 'blocked', 12.80, 100.00, 'critical', 'online', NULL, 'significant_change', '2026-09-30 18:50:35'),
(568, 1, 'FG-STATION-001', 57.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:51:00'),
(569, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.00, 0, 0, 'open', 'opening', 12.79, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:53:03'),
(570, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1975, 0, 0.00, 0, 0, 'paused', 'closing', 12.79, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:53:21'),
(571, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:53:53'),
(572, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1963, 0, 0.00, 1, 0, 'blocked', 'paused', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:54:53'),
(573, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.00, 0, 0, 'open', 'paused', 12.80, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:55:23'),
(574, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.00, 0, 1, 'open', 'blocked', 12.79, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 18:55:53'),
(575, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1960, 0, 0.00, 0, 1, 'open', 'blocked', 12.79, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-30 19:07:56'),
(576, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.00, 0, 1, 'open', 'blocked', 12.77, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-30 19:13:06'),
(577, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1963, 0, 0.00, 0, 0, 'open', 'open', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:14:37'),
(578, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1969, 0, 0.00, 0, 1, 'open', 'blocked', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:15:07'),
(579, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1968, 0, 0.00, 1, 0, 'blocked', 'open', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:16:08'),
(580, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1967, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.77, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:17:38'),
(581, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1964, 0, 0.60, 1, 1, 'blocked', 'blocked', 12.76, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-09-30 19:22:40'),
(582, 1, 'FG-STATION-001', 65.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1969, 0, 0.23, 0, 0, 'open', 'open', 12.75, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:23:13'),
(583, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1967, 0, 0.61, 0, 0, 'closing', 'closing', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:23:45'),
(584, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1964, 0, 0.61, 0, 0, 'paused', 'closed', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:24:18'),
(585, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1970, 0, 0.57, 0, 0, 'open', 'open', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:25:48'),
(586, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.60, 0, 0, 'closing', 'closing', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:29:16'),
(587, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1971, 0, 0.57, 0, 0, 'closed', 'paused', 12.77, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:29:49'),
(588, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.62, 0, 0, 'open', 'open', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:31:19'),
(589, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1962, 0, 0.59, 0, 0, 'closing', 'closing', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:34:40'),
(590, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1964, 0, 0.57, 0, 0, 'paused', 'closed', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:35:13'),
(591, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1963, 0, 0.56, 0, 0, 'open', 'opening', 12.75, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:35:20'),
(592, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.58, 0, 0, 'open', 'paused', 12.73, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:35:52'),
(593, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1962, 0, 0.56, 0, 0, 'closing', 'closed', 12.76, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:36:19'),
(594, 1, 'FG-STATION-001', 50.30, 0.00, NULL, NULL, 'unavailable', 'healthy', 1965, 0, 0.59, 0, 0, 'open', 'open', 12.74, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:36:33'),
(595, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.61, 0, 0, 'closing', 'closing', 12.74, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:41:24'),
(596, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1964, 0, 0.61, 0, 0, 'opening', 'open', 12.74, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:41:41'),
(597, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1964, 0, 0.59, 0, 0, 'closing', 'closing', 12.75, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:41:54'),
(598, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.60, 0, 0, 'paused', 'closed', 12.73, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:42:26'),
(599, 1, 'FG-STATION-001', 50.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 1966, 0, 0.24, 0, 0, 'open', 'open', 12.75, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-09-30 19:43:02'),
(600, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1986, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.65, 97.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 02:11:26'),
(601, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 1991, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.61, 95.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 02:16:30'),
(602, 1, 'FG-STATION-001', 46.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 1996, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.70, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 02:26:20'),
(603, 1, 'FG-STATION-001', 44.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 0, 1, 0.00, 1, 1, 'blocked', 'blocked', 12.62, 95.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:12:26'),
(604, 1, 'FG-STATION-001', 44.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 0, 1, 0.00, 1, 1, 'blocked', 'blocked', 1.19, 0.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:14:38'),
(605, 1, 'FG-STATION-001', 44.40, 0.00, NULL, NULL, 'unavailable', 'healthy', 2008, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.61, 94.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 03:14:56'),
(606, 1, 'FG-STATION-001', 40.40, 2.80, NULL, NULL, 'unavailable', 'healthy', 2008, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.60, 94.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 03:18:59'),
(607, 1, 'FG-STATION-001', 39.00, 4.20, NULL, NULL, 'unavailable', 'healthy', 2008, 0, 0.04, 1, 1, 'blocked', 'blocked', 12.59, 93.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 03:19:29'),
(608, 1, 'FG-STATION-001', 37.90, 5.30, NULL, NULL, 'unavailable', 'healthy', 2007, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.60, 94.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 03:19:47'),
(609, 1, 'FG-STATION-001', 35.90, 7.30, NULL, NULL, 'unavailable', 'healthy', 2006, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.59, 94.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 03:20:22'),
(610, 1, 'FG-STATION-001', 20.20, 23.00, NULL, NULL, 'unavailable', 'healthy', 2005, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.59, 94.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:22:39'),
(611, 1, 'FG-STATION-001', 31.90, 11.30, NULL, NULL, 'unavailable', 'healthy', 2006, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.59, 94.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:23:13'),
(612, 1, 'FG-STATION-001', 35.10, 8.00, NULL, NULL, 'unavailable', 'healthy', 2006, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.59, 94.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 03:23:18'),
(613, 1, 'FG-STATION-001', 34.90, 8.30, NULL, NULL, 'unavailable', 'healthy', 2007, 0, 0.04, 1, 1, 'blocked', 'blocked', 12.58, 93.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-10-01 03:28:23'),
(614, 1, 'FG-STATION-001', 35.00, 8.20, NULL, NULL, 'unavailable', 'healthy', 2005, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.68, 99.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 03:29:12'),
(615, 1, 'FG-STATION-001', 20.30, 22.90, NULL, NULL, 'unavailable', 'healthy', 2007, 0, 0.02, 1, 1, 'blocked', 'blocked', 12.67, 98.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:29:22'),
(616, 1, 'FG-STATION-001', 35.00, 8.20, NULL, NULL, 'unavailable', 'healthy', 2006, 0, 0.04, 1, 1, 'blocked', 'blocked', 12.67, 98.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 03:29:55'),
(617, 1, 'FG-STATION-001', 20.50, 22.70, NULL, NULL, 'unavailable', 'healthy', 2005, 0, 0.04, 1, 1, 'blocked', 'blocked', 12.67, 98.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 03:31:27'),
(618, 1, 'FG-STATION-001', 34.90, 8.30, NULL, NULL, 'unavailable', 'healthy', 2006, 0, 0.04, 1, 1, 'blocked', 'blocked', 12.66, 98.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 03:31:45'),
(619, 1, 'FG-STATION-001', 51.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 3609, 0, 1.52, 1, 1, 'blocked', 'blocked', 12.90, 100.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 04:33:22'),
(620, 1, 'FG-STATION-001', 49.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 2.09, 1, 1, 'blocked', 'blocked', 12.65, 97.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 04:38:28'),
(621, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 3310, 0, 0.08, 1, 1, 'blocked', 'blocked', 12.96, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 04:43:40'),
(622, 1, 'FG-STATION-001', 50.70, 0.00, NULL, NULL, 'unavailable', 'healthy', 3568, 0, 0.09, 1, 1, 'blocked', 'blocked', 12.85, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 04:58:28'),
(623, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 3463, 0, 0.03, 1, 1, 'blocked', 'blocked', 12.88, 100.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 05:03:37'),
(624, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3441, 1, 0.00, 1, 1, 'blocked', 'blocked', 12.88, 100.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 05:07:54'),
(625, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.61, 95.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:10:50'),
(626, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 0.00, 0.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:16:13'),
(627, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.61, 94.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:16:41'),
(628, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.61, 95.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 05:21:41'),
(629, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.60, 94.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 05:27:19'),
(630, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 1, 1, 'blocked', 'blocked', 12.60, 94.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:28:54'),
(631, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.60, 94.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:29:26'),
(632, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.45, 0, 1, 'open', 'blocked', 12.37, 81.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:45:24'),
(633, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.22, 0, 1, 'open', 'blocked', 12.37, 80.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 05:50:46'),
(634, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.45, 0, 0, 'open', 'open', 12.56, 92.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:51:16'),
(635, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.66, 0, 0, 'closing', 'paused', 12.56, 92.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:51:29'),
(636, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.60, 0, 0, 'opening', 'paused', 12.57, 92.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:51:52'),
(637, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.99, 0, 0, 'open', 'open', 12.57, 92.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 05:52:31'),
(638, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.44, 0, 1, 'open', 'blocked', 12.53, 90.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 07:53:11'),
(639, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 0, 'open', 'open', 12.52, 89.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 07:54:42'),
(640, 1, 'FG-STATION-001', 37.90, 5.30, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 0, 'open', 'open', 12.52, 89.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 07:56:17'),
(641, 1, 'FG-STATION-001', 37.70, 5.50, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 0, 'open', 'open', 12.52, 89.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 07:56:22'),
(642, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.35, 0, 0, 'open', 'open', 12.52, 89.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 07:57:01'),
(643, 1, 'FG-STATION-001', 50.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.52, 89.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 07:57:35'),
(644, 1, 'FG-STATION-001', 70.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 0.00, 0.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:21:17'),
(645, 1, 'FG-STATION-001', 49.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.52, 0, 1, 'open', 'blocked', 12.48, 87.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:21:45'),
(646, 1, 'FG-STATION-001', 50.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.58, 0, 0, 'open', 'open', 12.45, 85.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:26:58'),
(647, 1, 'FG-STATION-001', 50.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.57, 0, 1, 'open', 'blocked', 12.45, 86.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:27:29'),
(648, 1, 'FG-STATION-001', 49.60, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.43, 0, 1, 'open', 'blocked', 12.45, 86.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 08:32:35'),
(649, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.33, 0, 0, 'open', 'open', 12.45, 85.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:34:06'),
(650, 1, 'FG-STATION-001', 49.70, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.04, 0, 1, 'open', 'blocked', 12.45, 86.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:34:37'),
(651, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.35, 0, 0, 'open', 'open', 12.45, 85.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:38:44'),
(652, 1, 'FG-STATION-001', 50.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.60, 0, 1, 'open', 'blocked', 12.45, 85.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:39:14'),
(653, 1, 'FG-STATION-001', 48.90, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'open', 'blocked', 12.45, 85.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 08:44:24'),
(654, 1, 'FG-STATION-001', 50.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.57, 0, 0, 'open', 'open', 12.43, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:47:56'),
(655, 1, 'FG-STATION-001', 49.10, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.56, 0, 1, 'open', 'blocked', 12.43, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:48:27'),
(656, 1, 'FG-STATION-001', 47.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 0, 'open', 'open', 12.43, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:49:58'),
(657, 1, 'FG-STATION-001', 47.80, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.39, 0, 1, 'open', 'blocked', 12.42, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 08:50:29'),
(658, 1, 'FG-STATION-001', 50.00, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 1, 'open', 'blocked', 12.42, 84.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 08:55:34'),
(659, 1, 'FG-STATION-001', 49.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.57, 0, 1, 'open', 'blocked', 12.43, 84.00, 'normal', 'online', NULL, 'scheduled_sample', '2026-10-01 09:00:41'),
(660, 1, 'FG-STATION-001', 49.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 3138, 0, 0.13, 0, 0, 'open', 'open', 12.43, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:03:14'),
(661, 1, 'FG-STATION-001', 49.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 3314, 0, 0.56, 0, 1, 'open', 'blocked', 12.43, 84.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:03:44'),
(662, 1, 'FG-STATION-001', 49.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 3197, 0, 0.00, 0, 0, 'open', 'open', 12.42, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:04:14'),
(663, 1, 'FG-STATION-001', 49.50, 0.00, NULL, NULL, 'unavailable', 'healthy', 3310, 0, 0.13, 0, 1, 'open', 'blocked', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:04:45'),
(664, 1, 'FG-STATION-001', 42.10, 1.10, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.61, 0, 1, 'open', 'blocked', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:05:47'),
(665, 1, 'FG-STATION-001', 26.70, 16.50, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.22, 0, 1, 'closing', 'blocked', 12.41, 83.00, 'critical', 'online', NULL, 'significant_change', '2026-10-01 09:05:54'),
(666, 1, 'FG-STATION-001', 31.50, 11.70, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.62, 0, 1, 'closed', 'blocked', 12.40, 82.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 09:06:04'),
(667, 1, 'FG-STATION-001', 46.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.00, 0, 1, 'closed', 'blocked', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:06:26'),
(668, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.47, 0, 1, 'open', 'blocked', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:06:58'),
(669, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.56, 0, 0, 'open', 'open', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:07:59'),
(670, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 4095, 0, 0.60, 0, 1, 'open', 'blocked', 12.41, 83.00, 'normal', 'online', NULL, 'significant_change', '2026-10-01 09:08:29'),
(671, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3318, 1, 0.61, 0, 1, 'open', 'blocked', 12.41, 83.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 09:11:06'),
(672, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3437, 1, 0.61, 0, 1, 'open', 'blocked', 12.41, 83.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-10-01 09:16:13'),
(673, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3420, 1, 0.50, 0, 1, 'open', 'blocked', 12.40, 82.00, 'warning', 'online', NULL, 'scheduled_sample', '2026-10-01 09:21:19'),
(674, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3419, 1, 0.40, 0, 0, 'open', 'open', 12.40, 82.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 09:23:52'),
(675, 1, 'FG-STATION-001', 45.20, 0.00, NULL, NULL, 'unavailable', 'healthy', 3424, 1, 0.31, 0, 1, 'open', 'blocked', 12.40, 82.00, 'warning', 'online', NULL, 'significant_change', '2026-10-01 09:24:23');

-- --------------------------------------------------------

--
-- Table structure for table `sensor_summaries`
--

CREATE TABLE `sensor_summaries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `monitoring_device_id` bigint(20) UNSIGNED NOT NULL,
  `interval_start` datetime NOT NULL,
  `interval_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 15,
  `sample_count` int(10) UNSIGNED NOT NULL,
  `valid_sample_count` int(10) UNSIGNED NOT NULL,
  `min_water_level_cm` decimal(8,2) DEFAULT NULL,
  `avg_water_level_cm` decimal(8,2) DEFAULT NULL,
  `max_water_level_cm` decimal(8,2) DEFAULT NULL,
  `avg_wind_speed_mps` decimal(8,2) DEFAULT NULL,
  `max_wind_speed_mps` decimal(8,2) DEFAULT NULL,
  `rain_detected_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `highest_alert_level` enum('normal','warning','critical') NOT NULL DEFAULT 'normal',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sensor_summaries`
--

INSERT INTO `sensor_summaries` (`id`, `monitoring_device_id`, `interval_start`, `interval_minutes`, `sample_count`, `valid_sample_count`, `min_water_level_cm`, `avg_water_level_cm`, `max_water_level_cm`, `avg_wind_speed_mps`, `max_wind_speed_mps`, `rain_detected_count`, `highest_alert_level`, `created_at`) VALUES
(1, 1, '2026-08-11 20:15:00', 15, 1, 1, 107.70, 107.70, 107.70, 1.80, 1.80, 1, 'warning', '2026-09-08 03:32:15'),
(2, 1, '2026-08-14 16:00:00', 15, 1, 1, 19.50, 19.50, 19.50, NULL, NULL, 0, 'warning', '2026-09-08 03:32:15'),
(3, 1, '2026-08-14 16:15:00', 15, 1, 1, 19.50, 19.50, 19.50, NULL, NULL, 0, 'warning', '2026-09-08 03:32:15'),
(4, 1, '2026-08-14 16:45:00', 15, 5, 5, 0.00, 7.26, 14.40, NULL, NULL, 0, 'normal', '2026-09-08 03:32:15'),
(5, 1, '2026-08-14 17:00:00', 15, 23, 23, 0.00, 19.63, 29.80, NULL, NULL, 0, 'critical', '2026-09-08 03:32:15'),
(6, 1, '2026-08-14 17:15:00', 15, 3, 3, 10.80, 16.50, 22.90, NULL, NULL, 0, 'warning', '2026-09-08 03:32:15'),
(7, 1, '2026-08-18 12:15:00', 15, 7, 7, 5.60, 15.89, 29.80, NULL, NULL, 0, 'critical', '2026-09-08 03:32:15'),
(8, 1, '2026-08-18 12:30:00', 15, 19, 19, 7.70, 16.23, 29.70, NULL, NULL, 0, 'critical', '2026-09-08 03:32:15'),
(9, 1, '2026-08-18 12:45:00', 15, 10, 10, 4.10, 10.43, 29.80, NULL, NULL, 0, 'critical', '2026-09-08 03:32:15'),
(10, 1, '2026-08-18 13:00:00', 15, 5, 5, 5.80, 7.96, 10.30, NULL, NULL, 0, 'normal', '2026-09-08 03:32:15'),
(11, 1, '2026-08-18 13:15:00', 15, 8, 7, 3.80, 6.14, 8.20, 1.77, 2.23, 0, 'normal', '2026-09-08 03:32:15'),
(12, 1, '2026-08-18 13:45:00', 15, 1, 1, 6.10, 6.10, 6.10, 1.77, 1.77, 0, 'normal', '2026-09-08 03:32:15'),
(13, 1, '2026-08-20 12:45:00', 15, 17, 17, 1.50, 8.98, 14.10, 0.01, 0.09, 0, 'normal', '2026-09-08 03:32:15'),
(14, 1, '2026-08-20 13:00:00', 15, 24, 24, 1.40, 5.30, 7.40, 0.04, 0.14, 0, 'normal', '2026-09-08 03:32:15'),
(15, 1, '2026-08-20 13:15:00', 15, 26, 26, 1.10, 1.45, 2.30, 0.01, 0.08, 0, 'normal', '2026-09-08 03:32:15'),
(16, 1, '2026-08-20 13:30:00', 15, 26, 26, 1.40, 2.42, 21.20, 0.00, 0.00, 0, 'warning', '2026-09-08 03:32:15'),
(17, 1, '2026-08-20 13:45:00', 15, 30, 30, 1.40, 1.49, 1.50, 0.00, 0.04, 0, 'normal', '2026-09-08 03:32:15'),
(18, 1, '2026-08-20 14:00:00', 15, 29, 29, 1.40, 2.80, 18.90, 0.00, 0.04, 0, 'warning', '2026-09-08 03:32:15'),
(19, 1, '2026-08-20 14:15:00', 15, 35, 35, 0.00, 6.40, 27.60, 0.00, 0.04, 0, 'critical', '2026-09-08 03:32:15'),
(20, 1, '2026-08-20 14:30:00', 15, 15, 15, 0.00, 9.31, 28.30, 0.00, 0.06, 0, 'critical', '2026-09-08 03:32:15'),
(21, 1, '2026-08-24 14:00:00', 15, 4, 4, 11.60, 11.75, 12.20, 1.67, 2.67, 0, 'normal', '2026-09-08 03:32:15'),
(22, 1, '2026-08-24 14:15:00', 15, 12, 12, 11.60, 11.60, 11.60, 2.77, 3.37, 0, 'normal', '2026-09-08 03:32:15'),
(23, 1, '2026-08-24 14:30:00', 15, 23, 23, 1.40, 3.50, 25.70, 0.93, 2.23, 0, 'critical', '2026-09-08 03:32:15'),
(24, 1, '2026-08-24 14:45:00', 15, 32, 32, 1.50, 2.19, 18.20, 1.14, 6.96, 2, 'warning', '2026-09-08 03:32:15'),
(25, 1, '2026-08-24 15:00:00', 15, 28, 28, 1.50, 9.31, 14.60, 0.30, 5.60, 15, 'normal', '2026-09-08 03:32:15'),
(26, 1, '2026-08-24 15:15:00', 15, 14, 14, 14.20, 14.49, 14.60, 0.32, 0.75, 0, 'normal', '2026-09-08 03:32:15'),
(27, 1, '2026-08-24 15:45:00', 15, 16, 16, 1.10, 7.37, 8.90, 0.20, 0.83, 0, 'normal', '2026-09-08 03:32:15'),
(28, 1, '2026-08-24 16:00:00', 15, 9, 9, 1.50, 1.50, 1.50, 0.10, 0.60, 0, 'normal', '2026-09-08 03:32:15'),
(29, 1, '2026-08-25 23:00:00', 15, 19, 19, 0.70, 0.74, 0.80, 0.00, 0.00, 0, 'normal', '2026-09-08 03:32:15'),
(30, 1, '2026-08-25 23:30:00', 15, 7, 7, 0.90, 5.90, 29.70, 0.04, 0.11, 0, 'critical', '2026-09-08 03:32:15'),
(31, 1, '2026-08-26 01:15:00', 15, 23, 23, 2.50, 4.86, 21.50, 0.00, 0.00, 0, 'warning', '2026-09-08 03:32:15'),
(32, 1, '2026-08-26 01:30:00', 15, 13, 13, 2.30, 10.30, 25.10, 0.64, 7.22, 1, 'critical', '2026-09-08 03:32:15'),
(33, 1, '2026-08-26 06:15:00', 15, 12, 12, 0.00, 0.00, 0.00, 0.00, 0.00, 0, 'normal', '2026-09-08 03:32:15'),
(34, 1, '2026-08-26 07:30:00', 15, 12, 12, 2.30, 2.59, 2.90, 0.04, 0.13, 0, 'normal', '2026-09-08 03:32:15'),
(35, 1, '2026-08-26 07:45:00', 15, 33, 33, 2.70, 4.74, 29.70, 0.02, 0.09, 3, 'critical', '2026-09-08 03:32:15'),
(36, 1, '2026-08-26 08:00:00', 15, 7, 7, 2.70, 2.77, 2.80, 0.06, 0.13, 0, 'normal', '2026-09-08 03:32:15'),
(37, 1, '2026-09-08 10:00:00', 15, 1, 1, 10.00, 10.00, 10.00, 0.00, 0.00, 0, 'normal', '2026-09-08 03:32:15'),
(38, 1, '2026-09-08 10:15:00', 15, 2, 2, 10.00, 10.00, 10.00, 0.00, 0.00, 0, 'normal', '2026-09-08 03:32:15');

-- --------------------------------------------------------

--
-- Table structure for table `sms_logs`
--

CREATE TABLE `sms_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `alert_id` bigint(20) UNSIGNED DEFAULT NULL,
  `sensor_reading_id` bigint(20) UNSIGNED DEFAULT NULL,
  `resident_id` bigint(20) UNSIGNED DEFAULT NULL,
  `verification_id` bigint(20) UNSIGNED DEFAULT NULL,
  `mobile_number` varchar(11) NOT NULL,
  `recipient_type` enum('resident','non_resident') NOT NULL,
  `message_type` enum('alert','registration','otp') NOT NULL DEFAULT 'alert',
  `message` text NOT NULL,
  `delivery_status` enum('pending','sent','failed') NOT NULL DEFAULT 'pending',
  `claimed_by` varchar(50) DEFAULT NULL,
  `claimed_at` datetime DEFAULT NULL,
  `attempt_count` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `modem_response` text DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sms_logs`
--

INSERT INTO `sms_logs` (`id`, `alert_id`, `sensor_reading_id`, `resident_id`, `verification_id`, `mobile_number`, `recipient_type`, `message_type`, `message`, `delivery_status`, `claimed_by`, `claimed_at`, `attempt_count`, `modem_response`, `sent_at`, `created_at`) VALUES
(1, NULL, NULL, NULL, NULL, '09561347143', 'non_resident', 'alert', 'FloodGuard: Your SMS registration NR0001 was rejected. Reason: n/a n/a n/a Please submit a new registration with valid information or documents.', 'failed', NULL, NULL, 1, 'Cancelled old test message', NULL, '2026-08-03 01:13:45'),
(2, NULL, NULL, NULL, NULL, '09561347143', 'non_resident', 'alert', 'FloodGuard: Your SMS registration NR0001 was rejected. Reason: not verified Please submit a new registration with valid information or documents.', 'failed', NULL, NULL, 5, 'Cancelled before OTP test', NULL, '2026-08-20 04:47:42'),
(3, NULL, NULL, NULL, 1, '09494334497', 'resident', 'otp', 'FloodGuard verification code: 352759. This code expires in 5 minutes. Do not share this code.', 'failed', 'FG-STATION-001', '2026-08-20 12:56:14', 1, 'Replaced by a newer OTP.', NULL, '2026-08-20 04:55:27'),
(4, NULL, NULL, NULL, 1, '09494334497', 'resident', 'otp', 'FloodGuard verification code: 856377. This code expires in 5 minutes. Do not share this code.', 'failed', 'FG-STATION-001', '2026-08-20 12:58:52', 2, 'Replaced by a newer OTP.', NULL, '2026-08-20 04:56:49'),
(5, NULL, NULL, NULL, 1, '09494334497', 'resident', 'otp', 'FloodGuard verification code: 907414. This code expires in 5 minutes. Do not share this code.', 'failed', NULL, NULL, 2, 'Cancelled before fixed firmware test', NULL, '2026-08-20 05:00:54'),
(6, NULL, NULL, NULL, 1, '09494334497', 'resident', 'otp', 'FloodGuard verification code: 176517. This code expires in 5 minutes. Do not share this code.', 'failed', NULL, NULL, 3, 'Cancelled before fixed firmware test', NULL, '2026-08-20 05:05:26'),
(7, NULL, NULL, NULL, 2, '09999385385', 'non_resident', 'otp', 'FloodGuard verification code: 831448. This code expires in 5 minutes. Do not share this code.', 'failed', NULL, NULL, 3, 'Cancelled before fixed firmware test', NULL, '2026-08-20 05:18:54'),
(8, NULL, NULL, NULL, 2, '09999385385', 'non_resident', 'otp', 'FloodGuard verification code: 777548. This code expires in 5 minutes. Do not share this code.', 'failed', NULL, NULL, 1, 'Cancelled before fixed firmware test', NULL, '2026-08-20 05:28:13'),
(9, NULL, NULL, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard: Your SMS registration R0001 was rejected. Reason: n/aasaa Please submit a new registration with valid information or documents.', 'failed', NULL, NULL, 17, 'Cancelled old alert', NULL, '2026-08-20 05:30:35'),
(10, NULL, NULL, NULL, 3, '09561347142', 'resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-20 14:05:30', 7, 'A7670E accepted the SMS', '2026-08-20 14:05:32', '2026-08-20 05:37:03'),
(11, NULL, NULL, NULL, 3, '09561347142', 'resident', 'otp', 'FloodGuard verification code: 201650. This code expires in 5 minutes. Do not share this code.', 'failed', 'FG-STATION-001', '2026-08-20 13:57:02', 4, 'OTP expired or verification request removed.', NULL, '2026-08-20 05:50:48'),
(12, NULL, NULL, NULL, 3, '09561347142', 'resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-20 14:06:12', 1, 'A7670E accepted the SMS', '2026-08-20 14:06:13', '2026-08-20 06:06:08'),
(13, NULL, NULL, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard: Your SMS registration R0002 has been approved. You will now receive full community flood, weather, bridge, and emergency alerts.', 'sent', 'FG-STATION-001', '2026-08-20 14:07:01', 1, 'A7670E accepted the SMS', '2026-08-20 14:07:03', '2026-08-20 06:06:55'),
(14, NULL, 247, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:20:15', 1, 'A7670E accepted the SMS', '2026-08-20 14:20:17', '2026-08-20 06:20:12'),
(15, NULL, 248, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:20:30', 1, 'A7670E accepted the SMS', '2026-08-20 14:20:32', '2026-08-20 06:20:26'),
(16, NULL, 249, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:20:40', 1, 'A7670E accepted the SMS', '2026-08-20 14:20:42', '2026-08-20 06:20:39'),
(17, NULL, 250, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:20:56', 1, 'A7670E accepted the SMS', '2026-08-20 14:20:58', '2026-08-20 06:20:54'),
(18, NULL, 251, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:13', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:15', '2026-08-20 06:21:12'),
(19, NULL, 252, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:19', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:21', '2026-08-20 06:21:16'),
(20, NULL, 253, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 27.6 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:24', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:25', '2026-08-20 06:21:18'),
(21, NULL, 254, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:32', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:35', '2026-08-20 06:21:22'),
(22, NULL, 255, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:36', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:38', '2026-08-20 06:21:31'),
(23, NULL, 256, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:21:52', 1, 'A7670E accepted the SMS', '2026-08-20 14:21:54', '2026-08-20 06:21:52'),
(24, NULL, NULL, NULL, 4, '09494334497', 'non_resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-20 14:29:00', 1, 'A7670E accepted the SMS', '2026-08-20 14:29:02', '2026-08-20 06:28:59'),
(25, NULL, 271, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:29:33', 1, 'A7670E accepted the SMS', '2026-08-20 14:29:35', '2026-08-20 06:29:29'),
(26, NULL, 274, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:30:49', 1, 'A7670E accepted the SMS', '2026-08-20 14:30:51', '2026-08-20 06:30:46'),
(27, NULL, 278, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:32:25', 1, 'A7670E accepted the SMS', '2026-08-20 14:32:27', '2026-08-20 06:32:23'),
(28, NULL, NULL, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard: Your SMS registration NR0002 has been approved. You will now receive bridge closure, reopening, and unsafe-crossing alerts.', 'sent', 'FG-STATION-001', '2026-08-20 14:32:46', 1, 'A7670E accepted the SMS', '2026-08-20 14:32:48', '2026-08-20 06:32:41'),
(29, NULL, 280, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:03', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:04', '2026-08-20 06:33:00'),
(30, NULL, 280, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:08', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:09', '2026-08-20 06:33:00'),
(31, NULL, 281, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 26.8 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:19', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:21', '2026-08-20 06:33:18'),
(32, NULL, 281, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard CRITICAL: Water level is 26.8 cm. Stay away from the Spillway Bridge and use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:25', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:27', '2026-08-20 06:33:18'),
(33, NULL, 282, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:30', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:32', '2026-08-20 06:33:22'),
(34, NULL, 282, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:40', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:42', '2026-08-20 06:33:22'),
(35, NULL, 283, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 28.3 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:43', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:45', '2026-08-20 06:33:24'),
(36, NULL, 283, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard CRITICAL: Water level is 28.3 cm. Stay away from the Spillway Bridge and use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:48', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:49', '2026-08-20 06:33:24'),
(37, NULL, 284, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:53', 1, 'A7670E accepted the SMS', '2026-08-20 14:33:54', '2026-08-20 06:33:28'),
(38, NULL, 284, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-20 14:33:58', 1, 'A7670E accepted the SMS', '2026-08-20 14:34:00', '2026-08-20 06:33:28'),
(39, NULL, 309, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 25.7 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-24 14:37:23', 1, 'A7670E accepted the SMS', '2026-08-24 14:37:25', '2026-08-24 06:37:22'),
(40, NULL, 311, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:37:41', 1, 'A7670E accepted the SMS', '2026-08-24 14:37:43', '2026-08-24 06:37:38'),
(41, NULL, 311, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:37:46', 1, 'A7670E accepted the SMS', '2026-08-24 14:37:48', '2026-08-24 06:37:38'),
(42, NULL, 350, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-24 14:56:57', 1, 'A7670E accepted the SMS', '2026-08-24 14:56:59', '2026-08-24 06:56:56'),
(43, NULL, 350, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-24 14:57:02', 1, 'A7670E accepted the SMS', '2026-08-24 14:57:04', '2026-08-24 06:56:56'),
(44, NULL, 352, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:57:34', 1, 'A7670E accepted the SMS', '2026-08-24 14:57:36', '2026-08-24 06:57:34'),
(45, NULL, 352, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:57:39', 1, 'A7670E accepted the SMS', '2026-08-24 14:57:41', '2026-08-24 06:57:34'),
(46, NULL, 356, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-24 14:59:34', 1, 'A7670E accepted the SMS', '2026-08-24 14:59:44', '2026-08-24 06:59:31'),
(47, NULL, 356, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-24 14:59:49', 1, 'A7670E accepted the SMS', '2026-08-24 14:59:51', '2026-08-24 06:59:31'),
(48, NULL, 357, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:59:54', 1, 'A7670E accepted the SMS', '2026-08-24 14:59:56', '2026-08-24 06:59:48'),
(49, NULL, 357, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-24 14:59:59', 1, 'A7670E accepted the SMS', '2026-08-24 15:00:01', '2026-08-24 06:59:48'),
(50, NULL, NULL, NULL, 5, '09999385385', 'resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-25 23:10:55', 1, 'A7670E accepted the SMS', '2026-08-25 23:10:56', '2026-08-25 15:10:54'),
(51, NULL, NULL, NULL, NULL, '09999385385', 'resident', 'alert', 'FloodGuard: Your SMS registration R0003 was rejected. Reason: ID is not registered in San isidro Please submit a new registration with valid information or documents.', 'failed', 'FG-STATION-001', '2026-08-25 23:12:03', 1, 'A7670E SMS command failed', NULL, '2026-08-25 15:12:01'),
(52, NULL, NULL, NULL, 6, '09561347142', 'resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-25 23:34:33', 1, 'A7670E accepted the SMS', '2026-08-25 23:34:34', '2026-08-25 15:33:22'),
(53, NULL, NULL, NULL, NULL, '09561347142', 'resident', 'registration', 'FloodGuard: Registration R0004 was rejected. Reason: id is not resident in san isidro. You may correct the information and register again.', 'sent', 'FG-STATION-001', '2026-08-25 23:35:23', 1, 'A7670E accepted the SMS', '2026-08-25 23:35:25', '2026-08-25 15:35:22'),
(54, NULL, NULL, NULL, NULL, '09561347142', 'resident', 'registration', 'FloodGuard: Your SMS registration R0004 has been approved. You will now receive full community flood, weather, bridge, and emergency alerts.', 'sent', 'FG-STATION-001', '2026-08-25 23:36:24', 1, 'A7670E accepted the SMS', '2026-08-25 23:36:26', '2026-08-25 15:36:23'),
(55, NULL, 449, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 29.7 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-25 23:36:45', 1, 'A7670E accepted the SMS', '2026-08-25 23:36:46', '2026-08-25 15:36:44'),
(56, NULL, 450, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-25 23:36:50', 1, 'A7670E accepted the SMS', '2026-08-25 23:36:51', '2026-08-25 15:36:47'),
(57, NULL, 450, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-25 23:36:55', 1, 'A7670E accepted the SMS', '2026-08-25 23:36:57', '2026-08-25 15:36:47'),
(58, NULL, 451, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:18:36', 1, 'A7670E accepted the SMS', '2026-08-26 01:18:38', '2026-08-25 17:18:36'),
(59, NULL, 451, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:18:42', 1, 'A7670E accepted the SMS', '2026-08-26 01:18:44', '2026-08-25 17:18:36'),
(60, NULL, 452, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:18:47', 1, 'A7670E accepted the SMS', '2026-08-26 01:18:55', '2026-08-25 17:18:40'),
(61, NULL, 452, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:18:57', 1, 'A7670E accepted the SMS', '2026-08-26 01:18:59', '2026-08-25 17:18:40'),
(62, NULL, 455, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:20:13', 1, 'A7670E accepted the SMS', '2026-08-26 01:20:16', '2026-08-25 17:20:10'),
(63, NULL, 455, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:20:19', 1, 'A7670E accepted the SMS', '2026-08-26 01:20:21', '2026-08-25 17:20:10'),
(64, NULL, 456, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:20:24', 1, 'A7670E accepted the SMS', '2026-08-26 01:20:25', '2026-08-25 17:20:12'),
(65, NULL, 456, NULL, NULL, '09561347142', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:20:29', 1, 'A7670E accepted the SMS', '2026-08-26 01:20:30', '2026-08-25 17:20:12'),
(66, NULL, 461, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:22:39', 1, 'A7670E accepted the SMS', '2026-08-26 01:22:41', '2026-08-25 17:22:39'),
(67, NULL, 462, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:22:47', 1, 'A7670E accepted the SMS', '2026-08-26 01:22:48', '2026-08-25 17:22:42'),
(68, NULL, NULL, NULL, 7, '09561347142', 'non_resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-26 01:23:00', 1, 'A7670E accepted the SMS', '2026-08-26 01:23:02', '2026-08-25 17:22:56'),
(69, NULL, NULL, 7, NULL, '09561347142', 'non_resident', 'registration', 'FloodGuard: Your SMS registration NR0003 has been approved. You will now receive bridge closure, reopening, and unsafe-crossing alerts.', 'sent', 'FG-STATION-001', '2026-08-26 01:23:57', 1, 'A7670E accepted the SMS', '2026-08-26 01:23:59', '2026-08-25 17:23:57'),
(70, NULL, 477, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:29', 1, 'A7670E accepted the SMS', '2026-08-26 01:32:31', '2026-08-25 17:32:26'),
(71, NULL, 477, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:35', 1, 'A7670E accepted the SMS', '2026-08-26 01:32:36', '2026-08-25 17:32:26'),
(72, NULL, 478, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:40', 1, 'A7670E accepted the SMS', '2026-08-26 01:32:41', '2026-08-25 17:32:34'),
(73, NULL, 478, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:45', 1, 'A7670E accepted the SMS', '2026-08-26 01:32:52', '2026-08-25 17:32:34'),
(74, NULL, 479, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:54', 1, 'A7670E accepted the SMS', '2026-08-26 01:32:55', '2026-08-25 17:32:38'),
(75, NULL, 479, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:32:58', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:00', '2026-08-25 17:32:38'),
(76, NULL, 481, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:03', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:05', '2026-08-25 17:32:44'),
(77, NULL, 481, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:15', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:17', '2026-08-25 17:32:44'),
(78, NULL, 482, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:20', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:22', '2026-08-25 17:32:57'),
(79, NULL, 482, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:25', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:27', '2026-08-25 17:32:57'),
(80, NULL, 483, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:30', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:32', '2026-08-25 17:33:15'),
(81, NULL, 483, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:35', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:37', '2026-08-25 17:33:15'),
(82, NULL, 484, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:40', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:42', '2026-08-25 17:33:19'),
(83, NULL, 484, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard WARNING: The Spillway Bridge is unsafe to cross and is closed. Please use an alternate route.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:45', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:47', '2026-08-25 17:33:19'),
(84, NULL, 485, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 01:33:57', 1, 'A7670E accepted the SMS', '2026-08-26 01:33:59', '2026-08-25 17:33:23'),
(85, NULL, 485, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 06:22:42', 1, 'A7670E accepted the SMS', '2026-08-26 06:22:45', '2026-08-25 17:33:23'),
(86, NULL, NULL, NULL, 8, '09999385385', 'resident', 'otp', 'FloodGuard phone verification code sent.', 'sent', 'FG-STATION-001', '2026-08-26 07:41:25', 1, 'A7670E accepted the SMS', '2026-08-26 07:41:26', '2026-08-25 23:41:24'),
(87, NULL, NULL, 8, NULL, '09999385385', 'resident', 'registration', 'FloodGuard: Your SMS registration R0005 has been approved. You will now receive full community flood, weather, bridge, and emergency alerts.', 'sent', 'FG-STATION-001', '2026-08-26 07:42:15', 1, 'A7670E accepted the SMS', '2026-08-26 07:42:18', '2026-08-25 23:42:12'),
(88, NULL, 518, 8, NULL, '09999385385', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 29.6 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-26 07:48:37', 1, 'A7670E accepted the SMS', '2026-08-26 07:48:38', '2026-08-25 23:48:33'),
(89, NULL, 519, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:48:42', 1, 'A7670E accepted the SMS', '2026-08-26 07:48:43', '2026-08-25 23:48:35'),
(90, NULL, 519, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:48:47', 1, 'A7670E accepted the SMS', '2026-08-26 07:48:48', '2026-08-25 23:48:35'),
(91, NULL, 519, 8, NULL, '09999385385', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:48:52', 1, 'A7670E accepted the SMS', '2026-08-26 07:48:53', '2026-08-25 23:48:35'),
(92, NULL, 523, 8, NULL, '09999385385', 'resident', 'alert', 'FloodGuard CRITICAL: Water level is 29.7 cm. Follow barangay evacuation instructions and stay away from the Spillway Bridge.', 'sent', 'FG-STATION-001', '2026-08-26 07:50:23', 1, 'A7670E accepted the SMS', '2026-08-26 07:50:24', '2026-08-25 23:50:19'),
(93, NULL, 524, 4, NULL, '09494334497', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:50:28', 1, 'A7670E accepted the SMS', '2026-08-26 07:50:29', '2026-08-25 23:50:21'),
(94, NULL, 524, 7, NULL, '09561347142', 'non_resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:50:33', 1, 'A7670E accepted the SMS', '2026-08-26 07:50:35', '2026-08-25 23:50:21'),
(95, NULL, 524, 8, NULL, '09999385385', 'resident', 'alert', 'FloodGuard UPDATE: The Spillway Bridge is now open. Continue to cross with caution.', 'sent', 'FG-STATION-001', '2026-08-26 07:50:38', 1, 'A7670E accepted the SMS', '2026-08-26 07:50:40', '2026-08-25 23:50:21');

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `id` int(10) UNSIGNED NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`id`, `setting_key`, `setting_value`, `updated_at`) VALUES
(1, 'system_name', 'FloodGuard', '2026-09-29 08:56:08'),
(2, 'logo_path', 'assets/images/floodguard-logo.png', '2026-08-01 03:13:36'),
(3, 'location', 'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal', '2026-08-01 02:43:37'),
(4, 'device_id', 'FG-STATION-001', '2026-08-01 02:43:37'),
(5, 'warning_distance_cm', '70', '2026-08-01 02:43:37'),
(6, 'critical_distance_cm', '40', '2026-08-01 02:43:37'),
(7, 'obstacle_distance_cm', '20', '2026-08-01 02:43:37'),
(8, 'sensor_installation_height_cm', '0', '2026-08-01 02:43:37'),
(9, 'device_offline_timeout_seconds', '90', '2026-09-30 14:26:42'),
(10, 'station_name', 'Spillway Bridge Monitoring Station', '2026-08-22 11:05:53'),
(11, 'station_location', 'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal', '2026-08-22 11:05:53'),
(12, 'offline_timeout_seconds', '90', '2026-08-22 11:05:53'),
(13, 'dashboard_refresh_seconds', '30', '2026-08-22 11:05:53'),
(14, 'sensor_height_cm', '43.18', '2026-09-30 15:54:27'),
(15, 'warning_level_cm', '5.0', '2026-09-30 15:54:27'),
(16, 'critical_level_cm', '15.0', '2026-09-30 15:54:27'),
(17, 'sms_warning_enabled', '1', '2026-08-22 11:05:53'),
(18, 'sms_critical_enabled', '1', '2026-08-22 11:05:53'),
(19, 'sms_recovery_enabled', '1', '2026-08-22 11:05:53'),
(20, 'public_registration_enabled', '1', '2026-08-22 11:05:53'),
(21, 'otp_expiry_minutes', '5', '2026-08-22 11:05:53'),
(22, 'otp_resend_cooldown_seconds', '60', '2026-08-22 11:05:53'),
(23, 'registration_retry_minutes', '15', '2026-08-22 11:05:53'),
(24, 'public_poll_seconds', '5', '2026-09-08 03:49:07'),
(25, 'authenticated_poll_seconds', '5', '2026-09-10 02:39:01'),
(26, 'raw_telemetry_retention_days', '7', '2026-09-08 03:14:20'),
(27, 'sensor_reading_retention_days', '90', '2026-09-08 03:14:20'),
(28, 'sensor_summary_interval_minutes', '15', '2026-09-08 03:14:20'),
(29, 'legacy_sms_enabled', '0', '2026-09-08 03:14:20'),
(32, 'recommended_device_upload_seconds', '5', '2026-09-08 03:49:07'),
(33, 'recommended_sensor_sample_seconds', '1', '2026-09-08 03:49:07'),
(34, 'flood_report_max_photo_bytes', '10485760', '2026-09-08 04:10:45'),
(35, 'flood_report_allowed_image_types', 'image/jpeg,image/png,image/webp', '2026-09-08 04:10:45'),
(36, 'incident_location_retention_days', '30', '2026-09-08 04:10:45'),
(37, 'mobile_access_token_days', '30', '2026-09-08 04:42:53'),
(38, 'email_verification_minutes', '30', '2026-09-08 04:42:53'),
(39, 'resident_report_rate_limit_per_hour', '5', '2026-09-08 04:42:53'),
(40, 'sensor_history_interval_seconds', '300', '2026-09-10 02:39:01'),
(43, 'push_delivery_enabled', '1', '2026-09-28 09:34:32'),
(44, 'push_provider', 'firebase', '2026-09-10 05:39:15'),
(45, 'push_max_attempts', '3', '2026-09-10 05:39:15'),
(46, 'rain_warning_threshold', '3900', '2026-10-01 05:05:00'),
(47, 'rain_critical_threshold', '3200', '2026-10-01 05:05:00'),
(48, 'wind_warning_mps', '10.0', '2026-09-30 14:26:42'),
(49, 'wind_critical_mps', '20.0', '2026-09-30 14:26:42');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `account_status` enum('pending','active','inactive','suspended') NOT NULL DEFAULT 'pending',
  `last_login_at` datetime DEFAULT NULL,
  `token_version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `email_verified_at`, `account_status`, `last_login_at`, `token_version`, `created_at`, `updated_at`) VALUES
(1, 'FloodGuard Administrator', 'admin@floodguard.com', '$2y$10$ggQU7LLB6bVYB90GtFF45uq/0GghrslSWtzp//meBjWnHXDGE4ywK', '2026-09-04 12:47:03', 'active', '2026-10-01 15:53:45', 1, '2026-08-01 02:58:50', '2026-10-01 07:53:45'),
(2, 'FloodGuard Test Resident', 'resident.test@example.com', '$2y$10$vg0zy43XOktREyyv8D/7Je3voZqQaC94zJ/Ks75OxLVIt/zio1n3G', '2026-09-08 12:45:45', 'active', '2026-09-28 14:44:36', 4, '2026-09-08 04:45:26', '2026-09-28 06:44:36'),
(3, 'FloodGuard Barangay Personnel', 'barangay.test@example.com', '$2y$10$zxc5UYhFuV5YcE7e9gxp8.nfM7NzGXVyv8lgGaQvEvlCn0r/xj7l.', '2026-09-08 13:20:57', 'active', NULL, 1, '2026-09-08 05:20:57', '2026-09-08 05:20:57'),
(4, 'FloodGuard Response Coordinator', 'coordinator.test@example.com', '$2y$10$akCtjMKkdo26xHJrJZX6leJmml4vE9KKTrjzdHOX8WOQuzkc91t5y', '2026-09-09 08:25:22', 'inactive', NULL, 1, '2026-09-09 00:25:22', '2026-09-09 00:46:48'),
(5, 'FloodGuard Test Responder', 'responder.test@example.com', '$2y$10$6HOpMi5s25/eBv1RLDZ/z./wNsekts8UrsOX791hQNNzenrkMpplm', '2026-09-09 08:26:05', 'active', '2026-09-29 17:09:42', 1, '2026-09-09 00:26:05', '2026-09-29 09:09:42'),
(6, 'Kiff', 'bautistakiff@gmail.com', '$2y$10$7uyE0fOCg7Iy1rDWE7vHJee57zZG8LScXH/kLQSIPX00Aa0.VXLiG', '2026-09-24 16:58:33', 'active', NULL, 2, '2026-09-24 08:58:32', '2026-09-24 08:58:48'),
(7, 'Jec Antonio', 'itsmejericho0@gmail.com', '$2y$10$2cy27JMOk2VLkN7xzNXedeoPYp30yUCEjwmfJe4iceSSYG7Iyoywi', '2026-09-25 15:54:42', 'active', '2026-10-01 16:25:43', 5, '2026-09-25 04:18:11', '2026-10-01 08:25:43'),
(8, 'Jec', 'jericho1castillo@gmail.com', '$2y$10$/6tgUA4iP4dB4vwqRAMsBetScHs/s.sr0QNONguT8rha2CcbzyYFS', NULL, 'pending', NULL, 1, '2026-09-25 05:13:49', '2026-09-25 05:13:49'),
(9, 'Jec', 'jericho1castillo@gmil.com', '$2y$10$9dKi6Vz276ZXqnwVKmGTR.zXVj/dM95VNM4jF8GWDeSrqANtEHhcm', '2026-09-25 13:17:18', 'inactive', NULL, 2, '2026-09-25 05:15:44', '2026-09-25 05:29:09'),
(11, 'Kipp Jene Bautista', 'kip1@example.com', '$2y$10$mhVIl4U1Jwer/8fxJSceFuw5ri1MzkbHqGb9DoU5EVgglMHlCPLhe', '2026-10-01 10:38:44', 'active', '2026-10-01 11:45:24', 1, '2026-10-01 02:38:44', '2026-10-01 03:45:24'),
(12, 'Shemiel Asi', 'gioasi14@gmail.com', '$2y$10$FKI73aHGHX.A6UKHgEDMo.zfKsTgKGZhpujXEeiCVmt/y1wuZyYTu', '2026-10-01 10:43:31', 'active', '2026-10-01 10:46:25', 3, '2026-10-01 02:43:10', '2026-10-01 02:46:25'),
(13, 'Mark Owen', 'soy042705@gmail.com', '$2y$10$4tU2y5/eXzX2xe3MjPltIeX9u/pnLlIicN/6IdOtlrzQ.kwIqRKzy', '2026-10-01 16:53:16', 'active', '2026-10-01 17:13:38', 2, '2026-10-01 08:52:55', '2026-10-01 09:13:38');

-- --------------------------------------------------------

--
-- Table structure for table `user_roles`
--

CREATE TABLE `user_roles` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` smallint(5) UNSIGNED NOT NULL,
  `assigned_by` bigint(20) UNSIGNED DEFAULT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_roles`
--

INSERT INTO `user_roles` (`user_id`, `role_id`, `assigned_by`, `assigned_at`) VALUES
(1, 5, NULL, '2026-09-08 02:04:39'),
(2, 1, NULL, '2026-09-08 04:45:26'),
(3, 3, NULL, '2026-09-08 05:20:57'),
(5, 2, NULL, '2026-09-09 00:26:05'),
(6, 1, NULL, '2026-09-24 08:58:32'),
(7, 1, NULL, '2026-09-25 04:18:11'),
(8, 1, NULL, '2026-09-25 05:13:49'),
(9, 1, NULL, '2026-09-25 05:15:44'),
(11, 2, 1, '2026-10-01 02:38:44'),
(12, 1, NULL, '2026-10-01 02:43:10'),
(13, 1, NULL, '2026-10-01 08:52:55');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `alert_logs`
--
ALTER TABLE `alert_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_alert_sensor` (`sensor_reading_id`),
  ADD KEY `fk_alert_admin` (`created_by`),
  ADD KEY `idx_alert_level` (`alert_level`),
  ADD KEY `idx_alert_scope` (`alert_scope`),
  ADD KEY `idx_alert_created_at` (`created_at`);

--
-- Indexes for table `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_api_token_hash` (`token_hash`),
  ADD KEY `idx_api_tokens_user_active` (`user_id`,`revoked_at`,`expires_at`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_audit_actor_time` (`actor_user_id`,`created_at`),
  ADD KEY `idx_audit_entity` (`entity_type`,`entity_id`,`created_at`),
  ADD KEY `idx_audit_action_time` (`action`,`created_at`);

--
-- Indexes for table `community_posts`
--
ALTER TABLE `community_posts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_community_posts_number` (`post_number`),
  ADD KEY `idx_community_posts_resident_status` (`resident_user_id`,`status`),
  ADD KEY `idx_community_posts_public` (`status`,`published_at`),
  ADD KEY `fk_community_posts_reviewer` (`reviewer_user_id`);

--
-- Indexes for table `community_post_photos`
--
ALTER TABLE `community_post_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_community_post_photos_post` (`community_post_id`);

--
-- Indexes for table `community_post_status_history`
--
ALTER TABLE `community_post_status_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_community_post_history` (`community_post_id`,`created_at`),
  ADD KEY `fk_community_post_history_user` (`changed_by_user_id`);

--
-- Indexes for table `device_commands`
--
ALTER TABLE `device_commands`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_command_admin` (`requested_by`),
  ADD KEY `idx_command_status` (`command_status`),
  ADD KEY `idx_command_created_at` (`requested_at`),
  ADD KEY `idx_device_pending` (`device_id`,`command_status`,`expires_at`);

--
-- Indexes for table `device_commands_backup_20260822`
--
ALTER TABLE `device_commands_backup_20260822`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_command_admin` (`requested_by`),
  ADD KEY `idx_command_status` (`command_status`),
  ADD KEY `idx_command_created_at` (`created_at`);

--
-- Indexes for table `device_events`
--
ALTER TABLE `device_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_device_events_device_time` (`monitoring_device_id`,`occurred_at`),
  ADD KEY `idx_device_events_type_time` (`event_type`,`occurred_at`),
  ADD KEY `idx_device_events_reading` (`sensor_reading_id`);

--
-- Indexes for table `device_latest_readings`
--
ALTER TABLE `device_latest_readings`
  ADD PRIMARY KEY (`monitoring_device_id`),
  ADD UNIQUE KEY `uq_latest_sensor_reading` (`sensor_reading_id`);

--
-- Indexes for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_email_verification_hash` (`token_hash`),
  ADD KEY `idx_email_verification_user_expiry` (`user_id`,`expires_at`);

--
-- Indexes for table `flood_incidents`
--
ALTER TABLE `flood_incidents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_flood_incidents_number` (`incident_number`),
  ADD UNIQUE KEY `uq_flood_incidents_report` (`source_report_id`),
  ADD KEY `idx_incidents_operations` (`status`,`priority`,`created_at`),
  ADD KEY `idx_incidents_public` (`public_approved`,`status`,`created_at`),
  ADD KEY `fk_incidents_public_approver` (`public_approved_by`),
  ADD KEY `fk_incidents_verifier` (`resolution_verified_by`),
  ADD KEY `fk_incidents_creator` (`created_by`);

--
-- Indexes for table `flood_reports`
--
ALTER TABLE `flood_reports`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_flood_reports_number` (`report_number`),
  ADD KEY `idx_flood_reports_reporter_time` (`reporter_user_id`,`submitted_at`),
  ADD KEY `idx_flood_reports_review_queue` (`status`,`submitted_at`),
  ADD KEY `idx_flood_reports_reviewer` (`reviewed_by`);

--
-- Indexes for table `flood_report_photos`
--
ALTER TABLE `flood_report_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_report_photos_report` (`flood_report_id`),
  ADD KEY `fk_report_photos_uploader` (`uploaded_by`);

--
-- Indexes for table `flood_report_revisions`
--
ALTER TABLE `flood_report_revisions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_report_revision` (`flood_report_id`,`revision_number`),
  ADD KEY `fk_report_revisions_submitter` (`submitted_by`);

--
-- Indexes for table `flood_report_status_history`
--
ALTER TABLE `flood_report_status_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_report_history_report_time` (`flood_report_id`,`changed_at`),
  ADD KEY `fk_report_history_actor` (`changed_by`);

--
-- Indexes for table `incident_assignments`
--
ALTER TABLE `incident_assignments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_assignments_incident_status` (`flood_incident_id`,`status`),
  ADD KEY `idx_assignments_team_status` (`response_team_id`,`status`),
  ADD KEY `fk_assignments_assigner` (`assigned_by`),
  ADD KEY `fk_assignments_acceptor` (`accepted_by`);

--
-- Indexes for table `incident_status_history`
--
ALTER TABLE `incident_status_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_incident_history_incident_time` (`flood_incident_id`,`changed_at`),
  ADD KEY `fk_incident_history_assignment` (`assignment_id`),
  ADD KEY `fk_incident_history_actor` (`changed_by`);

--
-- Indexes for table `monitoring_devices`
--
ALTER TABLE `monitoring_devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_monitoring_devices_uid` (`device_uid`),
  ADD KEY `idx_monitoring_devices_status` (`is_active`,`operational_status`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_password_reset_hash` (`token_hash`),
  ADD KEY `idx_password_reset_user_expiry` (`user_id`,`expires_at`);

--
-- Indexes for table `pending_phone_verifications`
--
ALTER TABLE `pending_phone_verifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_pending_verification_token` (`verification_token`),
  ADD UNIQUE KEY `uq_pending_mobile_number` (`mobile_number`),
  ADD KEY `idx_pending_expiry` (`expires_at`),
  ADD KEY `idx_pending_existing_resident` (`existing_resident_id`);

--
-- Indexes for table `permissions`
--
ALTER TABLE `permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_permissions_slug` (`slug`);

--
-- Indexes for table `push_notifications`
--
ALTER TABLE `push_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_push_notifications_created` (`created_at`);

--
-- Indexes for table `push_notification_recipients`
--
ALTER TABLE `push_notification_recipients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_push_notification_user` (`push_notification_id`,`user_id`),
  ADD KEY `idx_push_recipient_inbox` (`user_id`,`read_at`,`created_at`),
  ADD KEY `idx_push_delivery_queue` (`delivery_status`,`attempt_count`,`created_at`);

--
-- Indexes for table `rate_limits`
--
ALTER TABLE `rate_limits`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_rate_limit_action_subject` (`action_key`,`subject_hash`),
  ADD KEY `idx_rate_limits_blocked_until` (`blocked_until`);

--
-- Indexes for table `registration_counters`
--
ALTER TABLE `registration_counters`
  ADD PRIMARY KEY (`applicant_type`);

--
-- Indexes for table `residents`
--
ALTER TABLE `residents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reference_no` (`reference_no`),
  ADD UNIQUE KEY `mobile_number` (`mobile_number`),
  ADD KEY `fk_resident_reviewer` (`reviewed_by`),
  ADD KEY `idx_resident_type` (`applicant_type`),
  ADD KEY `idx_resident_status` (`registration_status`),
  ADD KEY `idx_notification_scope` (`notification_scope`),
  ADD KEY `idx_resident_created_at` (`created_at`);

--
-- Indexes for table `resident_location_sharing`
--
ALTER TABLE `resident_location_sharing`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_resident_location_assignment` (`incident_assignment_id`),
  ADD KEY `idx_resident_location_sharing_user` (`resident_user_id`,`is_enabled`);

--
-- Indexes for table `resident_location_updates`
--
ALTER TABLE `resident_location_updates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_resident_location_assignment_time` (`incident_assignment_id`,`recorded_at`),
  ADD KEY `idx_resident_location_user_time` (`resident_user_id`,`recorded_at`);

--
-- Indexes for table `resident_profiles`
--
ALTER TABLE `resident_profiles`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_resident_profiles_mobile` (`mobile_number`),
  ADD KEY `idx_resident_profiles_barangay` (`barangay`),
  ADD KEY `idx_resident_profiles_approval` (`approval_status`,`created_at`),
  ADD KEY `fk_resident_profiles_reviewer` (`reviewed_by`);

--
-- Indexes for table `resident_push_devices`
--
ALTER TABLE `resident_push_devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_resident_push_token_hash` (`token_hash`),
  ADD KEY `idx_resident_push_user_active` (`user_id`,`revoked_at`);

--
-- Indexes for table `responder_location_updates`
--
ALTER TABLE `responder_location_updates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_responder_location_assignment_time` (`incident_assignment_id`,`recorded_at`),
  ADD KEY `idx_responder_location_user_time` (`responder_user_id`,`recorded_at`);

--
-- Indexes for table `response_teams`
--
ALTER TABLE `response_teams`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_response_teams_name` (`team_name`),
  ADD KEY `idx_response_teams_availability` (`is_active`,`duty_status`),
  ADD KEY `fk_response_teams_creator` (`created_by`);

--
-- Indexes for table `response_team_members`
--
ALTER TABLE `response_team_members`
  ADD PRIMARY KEY (`response_team_id`,`responder_user_id`),
  ADD KEY `idx_team_members_responder` (`responder_user_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_roles_slug` (`slug`);

--
-- Indexes for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD PRIMARY KEY (`role_id`,`permission_id`),
  ADD KEY `idx_role_permissions_permission` (`permission_id`);

--
-- Indexes for table `sensor_readings`
--
ALTER TABLE `sensor_readings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sensor_created_at` (`created_at`),
  ADD KEY `idx_sensor_alert_level` (`alert_level`),
  ADD KEY `idx_sensor_device_id` (`device_id`),
  ADD KEY `idx_prediction_status` (`prediction_status`),
  ADD KEY `idx_sensor_health` (`sensor_health`),
  ADD KEY `idx_sensor_device_created` (`monitoring_device_id`,`created_at`);

--
-- Indexes for table `sensor_summaries`
--
ALTER TABLE `sensor_summaries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sensor_summary_interval` (`monitoring_device_id`,`interval_start`,`interval_minutes`);

--
-- Indexes for table `sms_logs`
--
ALTER TABLE `sms_logs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sms_reading_recipient_type` (`sensor_reading_id`,`resident_id`,`message_type`),
  ADD KEY `fk_sms_alert` (`alert_id`),
  ADD KEY `fk_sms_resident` (`resident_id`),
  ADD KEY `idx_sms_delivery_status` (`delivery_status`),
  ADD KEY `idx_sms_created_at` (`created_at`),
  ADD KEY `idx_sms_pending_claim` (`delivery_status`,`claimed_at`,`created_at`),
  ADD KEY `idx_sms_verification_id` (`verification_id`),
  ADD KEY `idx_sms_sensor_reading` (`sensor_reading_id`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_status` (`account_status`);

--
-- Indexes for table `user_roles`
--
ALTER TABLE `user_roles`
  ADD PRIMARY KEY (`user_id`,`role_id`),
  ADD KEY `idx_user_roles_role` (`role_id`),
  ADD KEY `idx_user_roles_assigner` (`assigned_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `alert_logs`
--
ALTER TABLE `alert_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `api_tokens`
--
ALTER TABLE `api_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=69;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=94;

--
-- AUTO_INCREMENT for table `community_posts`
--
ALTER TABLE `community_posts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `community_post_photos`
--
ALTER TABLE `community_post_photos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `community_post_status_history`
--
ALTER TABLE `community_post_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `device_commands`
--
ALTER TABLE `device_commands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;

--
-- AUTO_INCREMENT for table `device_commands_backup_20260822`
--
ALTER TABLE `device_commands_backup_20260822`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `device_events`
--
ALTER TABLE `device_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=122;

--
-- AUTO_INCREMENT for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `flood_incidents`
--
ALTER TABLE `flood_incidents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `flood_reports`
--
ALTER TABLE `flood_reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `flood_report_photos`
--
ALTER TABLE `flood_report_photos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `flood_report_revisions`
--
ALTER TABLE `flood_report_revisions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `flood_report_status_history`
--
ALTER TABLE `flood_report_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `incident_assignments`
--
ALTER TABLE `incident_assignments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `incident_status_history`
--
ALTER TABLE `incident_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `monitoring_devices`
--
ALTER TABLE `monitoring_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `pending_phone_verifications`
--
ALTER TABLE `pending_phone_verifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `permissions`
--
ALTER TABLE `permissions`
  MODIFY `id` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `push_notifications`
--
ALTER TABLE `push_notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `push_notification_recipients`
--
ALTER TABLE `push_notification_recipients`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `rate_limits`
--
ALTER TABLE `rate_limits`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `residents`
--
ALTER TABLE `residents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `resident_location_sharing`
--
ALTER TABLE `resident_location_sharing`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `resident_location_updates`
--
ALTER TABLE `resident_location_updates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=65;

--
-- AUTO_INCREMENT for table `resident_push_devices`
--
ALTER TABLE `resident_push_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `responder_location_updates`
--
ALTER TABLE `responder_location_updates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `response_teams`
--
ALTER TABLE `response_teams`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `sensor_readings`
--
ALTER TABLE `sensor_readings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=676;

--
-- AUTO_INCREMENT for table `sensor_summaries`
--
ALTER TABLE `sensor_summaries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `sms_logs`
--
ALTER TABLE `sms_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=96;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `alert_logs`
--
ALTER TABLE `alert_logs`
  ADD CONSTRAINT `fk_alert_admin` FOREIGN KEY (`created_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_alert_sensor` FOREIGN KEY (`sensor_reading_id`) REFERENCES `sensor_readings` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD CONSTRAINT `fk_api_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `community_posts`
--
ALTER TABLE `community_posts`
  ADD CONSTRAINT `fk_community_posts_resident` FOREIGN KEY (`resident_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_community_posts_reviewer` FOREIGN KEY (`reviewer_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `community_post_photos`
--
ALTER TABLE `community_post_photos`
  ADD CONSTRAINT `fk_community_post_photos_post` FOREIGN KEY (`community_post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `community_post_status_history`
--
ALTER TABLE `community_post_status_history`
  ADD CONSTRAINT `fk_community_post_history_post` FOREIGN KEY (`community_post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_community_post_history_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `device_commands`
--
ALTER TABLE `device_commands`
  ADD CONSTRAINT `fk_command_admin` FOREIGN KEY (`requested_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `device_events`
--
ALTER TABLE `device_events`
  ADD CONSTRAINT `fk_device_events_device` FOREIGN KEY (`monitoring_device_id`) REFERENCES `monitoring_devices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_device_events_reading` FOREIGN KEY (`sensor_reading_id`) REFERENCES `sensor_readings` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `device_latest_readings`
--
ALTER TABLE `device_latest_readings`
  ADD CONSTRAINT `fk_latest_device` FOREIGN KEY (`monitoring_device_id`) REFERENCES `monitoring_devices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_latest_reading` FOREIGN KEY (`sensor_reading_id`) REFERENCES `sensor_readings` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD CONSTRAINT `fk_email_verification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `flood_incidents`
--
ALTER TABLE `flood_incidents`
  ADD CONSTRAINT `fk_incidents_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_incidents_public_approver` FOREIGN KEY (`public_approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_incidents_report` FOREIGN KEY (`source_report_id`) REFERENCES `flood_reports` (`id`),
  ADD CONSTRAINT `fk_incidents_verifier` FOREIGN KEY (`resolution_verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `flood_reports`
--
ALTER TABLE `flood_reports`
  ADD CONSTRAINT `fk_flood_reports_reporter` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_flood_reports_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `flood_report_photos`
--
ALTER TABLE `flood_report_photos`
  ADD CONSTRAINT `fk_report_photos_report` FOREIGN KEY (`flood_report_id`) REFERENCES `flood_reports` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_report_photos_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `flood_report_revisions`
--
ALTER TABLE `flood_report_revisions`
  ADD CONSTRAINT `fk_report_revisions_report` FOREIGN KEY (`flood_report_id`) REFERENCES `flood_reports` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_report_revisions_submitter` FOREIGN KEY (`submitted_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `flood_report_status_history`
--
ALTER TABLE `flood_report_status_history`
  ADD CONSTRAINT `fk_report_history_actor` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_report_history_report` FOREIGN KEY (`flood_report_id`) REFERENCES `flood_reports` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `incident_assignments`
--
ALTER TABLE `incident_assignments`
  ADD CONSTRAINT `fk_assignments_acceptor` FOREIGN KEY (`accepted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_assignments_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_assignments_incident` FOREIGN KEY (`flood_incident_id`) REFERENCES `flood_incidents` (`id`),
  ADD CONSTRAINT `fk_assignments_team` FOREIGN KEY (`response_team_id`) REFERENCES `response_teams` (`id`);

--
-- Constraints for table `incident_status_history`
--
ALTER TABLE `incident_status_history`
  ADD CONSTRAINT `fk_incident_history_actor` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_incident_history_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `incident_assignments` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_incident_history_incident` FOREIGN KEY (`flood_incident_id`) REFERENCES `flood_incidents` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD CONSTRAINT `fk_password_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `pending_phone_verifications`
--
ALTER TABLE `pending_phone_verifications`
  ADD CONSTRAINT `fk_pending_existing_resident` FOREIGN KEY (`existing_resident_id`) REFERENCES `residents` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `push_notification_recipients`
--
ALTER TABLE `push_notification_recipients`
  ADD CONSTRAINT `fk_push_recipient_notification` FOREIGN KEY (`push_notification_id`) REFERENCES `push_notifications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_push_recipient_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `residents`
--
ALTER TABLE `residents`
  ADD CONSTRAINT `fk_resident_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `resident_location_sharing`
--
ALTER TABLE `resident_location_sharing`
  ADD CONSTRAINT `fk_resident_location_sharing_assignment` FOREIGN KEY (`incident_assignment_id`) REFERENCES `incident_assignments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_resident_location_sharing_user` FOREIGN KEY (`resident_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `resident_location_updates`
--
ALTER TABLE `resident_location_updates`
  ADD CONSTRAINT `fk_resident_location_update_assignment` FOREIGN KEY (`incident_assignment_id`) REFERENCES `incident_assignments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_resident_location_update_user` FOREIGN KEY (`resident_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `resident_profiles`
--
ALTER TABLE `resident_profiles`
  ADD CONSTRAINT `fk_resident_profiles_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_resident_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `resident_push_devices`
--
ALTER TABLE `resident_push_devices`
  ADD CONSTRAINT `fk_resident_push_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `responder_location_updates`
--
ALTER TABLE `responder_location_updates`
  ADD CONSTRAINT `fk_responder_location_assignment` FOREIGN KEY (`incident_assignment_id`) REFERENCES `incident_assignments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_responder_location_user` FOREIGN KEY (`responder_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `response_teams`
--
ALTER TABLE `response_teams`
  ADD CONSTRAINT `fk_response_teams_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `response_team_members`
--
ALTER TABLE `response_team_members`
  ADD CONSTRAINT `fk_team_members_responder` FOREIGN KEY (`responder_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_team_members_team` FOREIGN KEY (`response_team_id`) REFERENCES `response_teams` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sensor_readings`
--
ALTER TABLE `sensor_readings`
  ADD CONSTRAINT `fk_sensor_monitoring_device` FOREIGN KEY (`monitoring_device_id`) REFERENCES `monitoring_devices` (`id`);

--
-- Constraints for table `sensor_summaries`
--
ALTER TABLE `sensor_summaries`
  ADD CONSTRAINT `fk_sensor_summaries_device` FOREIGN KEY (`monitoring_device_id`) REFERENCES `monitoring_devices` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sms_logs`
--
ALTER TABLE `sms_logs`
  ADD CONSTRAINT `fk_sms_alert` FOREIGN KEY (`alert_id`) REFERENCES `alert_logs` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_sms_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_roles`
--
ALTER TABLE `user_roles`
  ADD CONSTRAINT `fk_user_roles_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_user_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
