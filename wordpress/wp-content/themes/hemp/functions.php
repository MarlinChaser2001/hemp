<?php
/**
 * Hemp — child theme of Twenty Twenty-Five.
 *
 * Layout and styling are block-based: templates and global styles live in the
 * Site Editor, brand tokens in theme.json, and one-off CSS in style.css.
 *
 * This file only declares WooCommerce support, which switches the shop, cart,
 * checkout and product blocks into their full (non-placeholder) form.
 *
 * @package Hemp
 */

declare(strict_types=1);

add_action(
	'after_setup_theme',
	static function (): void {
		add_theme_support( 'woocommerce' );

		// Product gallery on the single-product template.
		add_theme_support( 'wc-product-gallery-zoom' );
		add_theme_support( 'wc-product-gallery-lightbox' );
		add_theme_support( 'wc-product-gallery-slider' );
	}
);
