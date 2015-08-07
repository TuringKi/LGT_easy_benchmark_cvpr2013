
parameters.modalities.mask = 20;
parameters.modalities.window = 150;

parameters.modalities.shape.enabled = 1;
parameters.modalities.shape.expand = 10;
parameters.modalities.shape.persistence = 0.7;

parameters.modalities.motion.enabled = 1;
parameters.modalities.motion.lk_size=8;
parameters.modalities.motion.lk_layers = 2;
parameters.modalities.motion.harris_threshold = 20;
parameters.modalities.motion.persistence = 0.70;
parameters.modalities.motion.damping = 1;

parameters.modalities.color.enabled = 1;
parameters.modalities.color.color_space = 'hsv';
parameters.modalities.color.bins = [16, 16, 4];
parameters.modalities.color.fg_persistence=0.95;
parameters.modalities.color.fg_sampling = 3;
parameters.modalities.color.bg_persistence = 0.5;
parameters.modalities.color.bg_sampling=[10 35];

parameters.optimization.global_move = 20;
parameters.optimization.global_rotate = 0.08;
parameters.optimization.global_scale = 0.005;
parameters.optimization.global_samples_min = 50;
parameters.optimization.global_samples_max = 300;
parameters.optimization.global_elite = 10;
parameters.optimization.local_fix = 0.8;
parameters.optimization.local_radius = 5;
parameters.optimization.local_samples = 40;
parameters.optimization.local_elite = 5;
parameters.optimization.iterations = 10;
parameters.optimization.rigidity = 0.0148;
parameters.optimization.visual = 1;

parameters.merge = 3;
 
%parameters.weight.good = 0.8;
parameters.weight.remove = 0.1;

parameters.reweight.remove = 0.1;
parameters.reweight.distance = 3;
parameters.reweight.similarity = 3;

parameters.size = 50;

parameters.pool.min = 6;
parameters.pool.max = 36;
parameters.pool.init = 20;
parameters.pool.persistence = 0.8;

parameters.motion.system_noise = 1;
parameters.motion.measurement_noise = 1;
