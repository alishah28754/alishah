// backend/routes/users.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { Op } = require('sequelize');

// ============================================================
// GET ALL USERS (for admin panel)
// ============================================================
router.get('/', async (req, res) => {
  try {
    const { limit = 100, offset = 0, search = '' } = req.query;
    
    const where = {};
    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where,
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    res.json({
      success: true,
      data: rows,
      total: count,
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// GET USER BY ID
// ============================================================
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// GET USER BY EMAIL
// ============================================================
router.get('/email/:email', async (req, res) => {
  try {
    const user = await User.findOne({ 
      where: { email: req.params.email } 
    });
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// CREATE OR UPDATE USER (sync from Firebase)
// ============================================================
router.post('/sync', async (req, res) => {
  try {
    const { 
      firebase_uid, 
      name, 
      email, 
      phone, 
      profile_image, 
      provider, 
      is_email_verified 
    } = req.body;

    if (!firebase_uid || !email) {
      return res.status(400).json({ 
        success: false, 
        error: 'firebase_uid and email are required' 
      });
    }

    // Check if user exists by firebase_uid
    let user = await User.findOne({ where: { firebase_uid } });

    if (user) {
      // Update existing user
      await user.update({
        name: name || user.name,
        email: email || user.email,
        phone: phone || user.phone,
        profile_image: profile_image || user.profile_image,
        provider: provider || user.provider,
        is_email_verified: is_email_verified ?? user.is_email_verified,
        last_login: new Date(),
        login_count: user.login_count + 1,
        updated_at: new Date(),
      });
    } else {
      // Check if user exists by email (for migration/fallback)
      let existingByEmail = await User.findOne({ where: { email } });
      
      if (existingByEmail) {
        // Update the existing user with firebase_uid
        await existingByEmail.update({
          firebase_uid,
          name: name || existingByEmail.name,
          phone: phone || existingByEmail.phone,
          profile_image: profile_image || existingByEmail.profile_image,
          provider: provider || existingByEmail.provider,
          is_email_verified: is_email_verified ?? existingByEmail.is_email_verified,
          last_login: new Date(),
          login_count: existingByEmail.login_count + 1,
          updated_at: new Date(),
        });
        user = existingByEmail;
      } else {
        // Create new user
        user = await User.create({
          firebase_uid,
          name: name || email.split('@')[0],
          email,
          phone: phone || '',
          profile_image: profile_image || '',
          provider: provider || 'email',
          is_email_verified: is_email_verified || false,
          last_login: new Date(),
          login_count: 1,
          is_active: true,
        });
      }
    }

    res.json({ 
      success: true, 
      data: user,
      message: user ? 'User updated' : 'User created'
    });
  } catch (error) {
    console.error('Error syncing user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// UPDATE USER PROFILE
// ============================================================
router.put('/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const { name, phone, profile_image, is_active } = req.body;
    await user.update({
      name: name || user.name,
      phone: phone || user.phone,
      profile_image: profile_image || user.profile_image,
      is_active: is_active !== undefined ? is_active : user.is_active,
      updated_at: new Date(),
    });

    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// DELETE USER
// ============================================================
router.delete('/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    await user.destroy();
    res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// GET USER STATS (for dashboard)
// ============================================================
router.get('/stats/summary', async (req, res) => {
  try {
    const totalUsers = await User.count();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const newToday = await User.count({
      where: { created_at: { [Op.gte]: today } }
    });
    
    const activeUsers = await User.count({
      where: { is_active: true }
    });

    res.json({
      success: true,
      data: {
        total_users: totalUsers,
        new_today: newToday,
        active_users: activeUsers,
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;