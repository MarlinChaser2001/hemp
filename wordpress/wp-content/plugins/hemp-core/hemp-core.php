<?php
/**
 * Plugin Name: Hemp Core
 * Description: Home for Hemp-specific store logic (product types, checkout tweaks, integrations). Keep it free of theme code so it survives a redesign.
 * Version: 0.1.0
 * Requires at least: 6.7
 * Requires PHP: 8.1
 * Author: Hemp
 * Text Domain: hemp-core
 *
 * @package HempCore
 */

declare(strict_types=1);

defined( 'ABSPATH' ) || exit;

if ( ! defined( 'HEMP_CORE_VERSION' ) ) {
	define( 'HEMP_CORE_VERSION', '0.1.0' );
}

// Add store logic here as the shop takes shape. Nothing is wired up yet on
// purpose — currency, tax and shipping belong in WooCommerce settings until
// there is a requirement that settings can't express.
